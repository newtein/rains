
# rainsd Architecture and Design

The RAINS server itself is made up of several components:

- A server query engine (`engine.go`): This component stores the assertions
  the server knows about, the queries it doesn't yet have answers to.
- A verification engine (`verify.go`): This component stores delegations the
  server knows about, and uses these to verify signatures on assertions from
  the root.
- A message processor (`inbox.go`): This component processes incoming
  messages, demarshaling them, verifying their signatures, and handing them to
  the query engine for further processing.
- A switchboard (`switchboard.go`): The other components of rainsd operate in
  terms of messages associated with a RAINS server identity. The switchboard
  maintains open connections to other RAINS servers using a least-recently used
  cache, reopening connections that have timed out.

In addition, the RAINS server uses the following component provided by `rainslib`:

- A data model implementation (`model.go`): This component defines the core runtime data types,
  handles marshaling and unmarshaling of RAINS messages into and out of CBOR, the parsing and
  generation of RAINS zonefiles, and utilities for signing assertions and verifying signatures.

The arrangement of these components is shown in the figure below:

![rainsd component diagram](rainsd.png)

## Query Engine Design

The query engine is built around two tables: an *assertion cache*, a
*pending queries cache*..

The assertion cache stores assertions this instance knows about, indexed by
the fields in a query: context, zone, name, object type. Each entry has an
expiration time, derived from the last-expiring signature on an assertion, to
aid in reaping expired entries. The assertion cache should be able to return
both a value (for internal queries, i.e. when the RAINS server itself needs to
know another RAINS server's address to connect to it) as well as an assertion
(in order to answer queries from peers).

Assertions in the assertion cache are assumed to have valid signatures at the
time of insertion into the assertion cache; it is the responsibility of the
message processor to check for validity (and to handle errors for invalid
signatures).

Note that the assertion cache is a candidate for refactoring into `rainslib`
as it might be useful in the RAINS client implementation, as well.

The pending queries cache stores unexpired queries for which assertions are
not yet available. A query that cannot be immediately answered is placed into
the pending queries cache, and checked against incoming assertions until it
expires.

The query engine has a simple API, with three entry points:

- `assert(assertion)`: add an assertion to the assertion cache. Trigger any
   pending queries answered by it. The assertion's signatures are assumed to have
   already been verified through the verification engine. Validity times are
   taken from the signatures
- `assert(shard)`: add a shard full of assertions to the assertion cache. The
   shard's signature is assumed to have been already been verified through the
   verification engine. adds information about the shard to the range index. recursively asserts contained assertions.
- `assert(zone)`: add a zone full of assertions to the assertion cache. The
   shard's signature is assumed to have been already been verified through the
   verification engine. adds information about the zone 
- `query(query, callback)`: Run the specified callback when the query is
   answerable. Do so immediately on an assertion cache hit, or after an assertion
   is available
- `reap()`: remove expired queries and assertions. This is
   probably simply called by a goroutine waiting on a tick channel.

The design of the internal data structures for the query engine is separate
from that of the `rainslib` data model. The `rainslib` data model is optimized
to be close to the wire, and easy to marshal/unmarshal to and from CBOR. The
query engine structures are optimized for fast access given a key (name to
zone, name to contexts, context/zone/name/type(s) to assertions and/or
queries). The query engine structures point either to raw assertions or raw
queries in the `rainslib` data model, as "provenance" for a given question or answer. 

Care must be taken in this design to handle nonexistence proofs based on
shards efficiently. Suggestion: when asserting a shard, add it (as provenance)
to a range index, and consult this range on a cache miss. Zones should be
similarly stored (without range index), and returned as a last resort.

## Verification Engine Design

The verification engine caches the current set of public keys used to verify
assertions in each zone the server knows about. It is fed delegation
assertions by the query engine when they are received, and may issue queries
using the query engine when missing a key needed to verify a signature chain.

It takes incoming assertions and verifies their signatures. It has the following entry points:

- `delegate(context, zone, cipher, key, until)`: add a delegation to the cache, called by the query engine for each delegation assertion received.
- `verify(assertion) -> assertion or nil`: verify an assertion. strip any signatures that did not verify. if no signatures remain, returns nil.
- `verify(shard) -> assertion or nil`: verify a shard. recursively verify contained assertions which have their own signatures. strip any signatures that did not verify. if no signatures remain, returns nil.
- `verify(zone) -> assertion or nil`: verify a shard. recursively verify contained shards and assertions which have their own signatures. strip any signatures that did not verify. if no signatures remain, returns nil.
- `reap()`: remove expired delegations. This is probably simply called by a goroutine waiting on a tick channel.

## Inbox Design

The inbox's ensures that each section of each incoming message gets handled to
completion or expiry. It provides a single entry point, `deliver(message,
from)`, which unpacks the incoming message, verifies signatures on it and on
its sections using the verification engine, then processes it, using either
the query() or assert() entry points on the query engine.

## Switchboard Design

The switchboard listens for incoming connections from servers or clients,
opens connections to servers to which messages need to be sent but for which
no active connection is available, and maintains actively opened and passively
opened connections to servers and clients on a most-recently-used basis. It
provides a single entry point, `sendto(message, to)`, which sends a message to
a named RAINS server.


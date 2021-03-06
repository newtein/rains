@0xfb2d77234707241e; # unique file ID, generated by `capnp id`
using Go = import "/go.capnp";
$Go.package("proto");
$Go.import("rains/proto");

struct RainsMessage  {
    #RainsMessage contains the data of a message
    signatures      @0 :List(Signature);
    capabilities    @1 :List(Text);
    token           @2 :Data;
    content         @3 :List(MessageSection);
}

struct MessageSection  {
    union {
        addressQuery        @0 :AddressQuerySection;
        addressZone         @1 :AddressZoneSection;
        addressAssertion    @2 :AddressAssertionSection;
        assertion           @3 :AssertionSection;
        shard               @4 :ShardSection;
        zone                @5 :ZoneSection;
        query               @6 :QuerySection;
        notification        @7 :NotificationSection;
    }   
}

struct AssertionSection  {
    #AssertionSection contains information about the assertion
    signatures  @0 :List(Signature);
    subjectName @1 :Text;
    subjectZone @2 :Text;
    context     @3 :Text;
    content     @4 :List(Obj);
}

struct ShardSection  {
    #ShardSection contains information about the shard
    signatures  @0 :List(Signature);
    subjectZone @1 :Text;
    context     @2 :Text;
    rangeFrom   @3 :Text;
    rangeTo     @4 :Text;
    content     @5 :List(AssertionSection);
}


struct ZoneSection  {
    #ZoneSection contains information about the zone
    signatures  @0  :List(Signature);
    subjectZone @1  :Text;
    context     @2  :Text;
    content     @3  :List(MessageSection);
}

struct QuerySection  {
    #QuerySection contains information about the query
    context @1      :Text;
    name    @0      :Text;
    types   @2      :List(Int32);
    expires @3      :Int64; #time when this query expires represented as the number of seconds elapsed since January 1, 1970 UTC
    options @4      :List(Int32);
}

struct AddressAssertionSection  {
    #AddressAssertionSection contains information about the address assertion
    signatures  @0  :List(Signature);
    subjectAddr @1  :Text;
    context     @2  :Text;
    content     @3  :List(Obj);
}


struct AddressZoneSection  {
    #AddressZoneSection contains information about the address zone
    signatures  @0  :List(Signature);
    subjectAddr @1  :Text;
    context     @2  :Text;
    content     @3  :List(AddressAssertionSection);
}

struct AddressQuerySection  {
    #AddressQuerySection contains information about the address query
    subjectAddr @0 :Text;
    context     @1 :Text;
    types       @2 :List(Int32);
    expires     @3 :Int64;
    options     @4 :List(Int32);
}


struct NotificationSection  {
    #NotificationSection contains information about the notification
    token @0    :Data;
    type  @1    :Int32;
    data  @2    :Text;
}


struct Signature  {
    #Signature on a Rains message or section
    algorithm  @0 :Int32;
    keySpace   @1 :Int32;
    validSince @2 :Int64;
    validUntil @3 :Int64;
    keyPhase   @4 :Int32;
    data       @5 :Data;
}

struct PublicKey  {
    #PublicKey contains information about a public key
    type       @0 :Int32;
    keySpace   @1 :Int32;
    validSince @2 :Int64;
    validUntil @3 :Int64;
    keyPhase   @4 :Int32;
    key        @5 :Data;
}

struct CertificateObject  {
    #CertificateObject contains certificate information
    type     @0 :Int32;
    usage    @1 :Int32;
    hashAlgo @2 :Int32;
    data     @3 :Data;
}

struct ServiceInfo  {
    #ServiceInfo contains information how to access a named service
    name     @0 :Text;
    port     @1 :UInt16;
    priority @2 :UInt32;
}

struct Obj  {
    #Object is a container for different values determined by the given type.
    type  @0    :Int32;
    value       :union {
        name    @1  :List(Text);
        ip6     @2  :Text;
        ip4     @3  :Text;
        redir   @4  :Text;
        deleg   @5  :PublicKey;
        nameset @6  :Text;
        cert    @7  :CertificateObject;
        service @8  :ServiceInfo;
        regr    @9  :Text;
        regt    @10 :Text;
        infra   @11 :PublicKey;
        extra   @12 :PublicKey;
        next    @13 :PublicKey;
    }
}

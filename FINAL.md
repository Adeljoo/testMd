**KPN Data Services Hub (DSH)**

**User Guide**

**API Client Connection Setup (MQTT)**

**TABLE OF CONTENTS**

\
=

1 BASIC CONCEPTS
================

1.1 Overview
------------

The core of the DSH platform is the set of data streams it manages. In
the platform, these streams are carried over Kafka topics. Tenants with
containers running on the platform can access them via the Kafka
protocol (subject to various Authorization Command Lines, or ACLs).

External devices and applications cannot directly access the data
streams over Kafka, but they can access a subset of the data streams
(the “public” data streams) over MQTT. The MQTT protocol adapter makes
the translation between both protocols and data representations.

Before an external device/application gets access to the platform, it
needs to authenticate itself. For this, the DSH features an
authentication service, where the client can authenticate itself (as
described in the documentation), and acquire an MQTT token (which is, in
reality, a JWT token that encodes the access rights granted to the
client). Upon connection to the MQTT protocol adapter, the client
presents this token as proof of identity and authorization. The MQTT
adapter will coordinate with the authentication service to verify the
authenticity of the token, and will further enforce the access rights
encoded in the token during the client's entire session.

Access rights are configured via the DSH Management Service. There are
two user-facing front ends to the Management Service: the Platform
Management Portal, which is used by SRE/operations personnel, and the
DSH Console, which is used by tenant developers for the management of
tenant resources on the platform.

**MQTT in the Data Services Hub**

![](media/image1.jpg){width="4.994792213473316in"
height="3.2870866141732282in"}

1.2 Data Stream
---------------

Data streams are the heart of the DSH platform. Each data stream carries
information of a specific kind, for example, in a smart city scenario,
it may carry weather data or parking lot occupation data.

1.3 API Clients
---------------

An API Client is an entity that connects applications and edge devices
to the DSH platform via the public DSH APIs. These applications and
devices can consume data from various streams on the platform, or
contribute to data streams by injecting data into the platform.

1.4 API Keys
------------

Every API Client gets assigned a unique API Key which is used as the
master authentication secret for all client devices and applications
managed by this API client.

1.5 User and Device Management
------------------------------

User and Device Management is the practice of managing the credentials
and access rights of, and providing configuration details to,
applications, devices and users.

This is an API client responsibility. DSH does not offer this
functionality in and of itself. Rather, the authentication and
authorization mechanisms implemented by DSH offer sufficient flexibility
for API clients to set up whatever authorization and authentication
mechanisms they desire.

1.6 MQTT
--------

The DSH platform exposes its data streams publicly via a subset of the
Message Queuing Telemetry Transport (MQTT) protocol
([*http://mqtt.org*](http://mqtt.org)). Each data stream is mapped to a
subset of the MQTT topic hierarchy.

1.7 Authentication Tokens
-------------------------

All MQTT connections to the platform must be authenticated. DSH does not
support username/password authentication directly. Instead, MQTT clients
must acquire an authentication token first, and pass that along during
connection setup in the password field of the MQTT CONNECT message.

The authentication tokens used by DSH are JSON Web Tokens (JWTs)
([*http://jwt.io*](http://jwt.io)). In some cases, it is useful to
understand the structure and contents of the authentication token as
this can be used to convey some basic configuration information about
the platform to the client device or application.

1.8 External Clients
--------------------

An external client is any device or application that connects to the DSH
platform via its public APIs with the intention of consuming, or
contributing to, data streams. In practice, this means any application
or device that sets up an MQTT connection to the DSH platform.

While we try to use this terminology consistently throughout the
documentation, you may occasionally encounter terms like client
application, client device or edge device. These are just synonyms for
external client.

2 MQTT
======

2.1 Standards Compliance
------------------------

The DSH platform implements a subset of the MQTT 3.1.1 protocol
([*http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html*](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html)).

Any standards-compliant MQTT client should be able to connect to the
platform without issues.

2.2 Unsupported Features
------------------------

The following features defined in the MQTT specification are not
supported by the DSH MQTT protocol adapter:

-   QoS 2

-   QoS 1 for subscriptions (all subscriptions will be automatically
    downgraded to QoS 0)

-   Last-will-and-testament

-   Session resumption (every connection is treated as if the
    clean-session flag was set\
    on connect)

2.3 Extensions
--------------

The DSH platform implements wildcard publications ([*see Section
2.9*](#wildcard-publications) for more information) as an extension to
the MQTT protocol.

2.4 MQTT Topic Structure
------------------------

DSH data streams are mapped to MQTT topics according to the following
pattern:

&lt;topic-prefix&gt;/&lt;stream-name&gt;/&lt;message key&gt;

The concepts of topic-prefix and stream-name also return in the MQTT
ACLs encoded in the MQTT token: ([*see Section
3.3.2.4*](#topic-patterns) for more information)

-   topic-prefix is a fixed prefix. In theory, this can be different for
    each data stream, but in practice it is always /tt

-   stream-name is the name of the DSH public data stream, e.g. weather

-   This name will ***never*** include / characters, and hence will
    always be a single path segment.

-   message key is the key with which the message was published on the
    DSH's internal Kafka bus.

2.5 Authentication
------------------

Before an MQTT client can connect to the platform, it must acquire an
**MQTT Token** ([*see Section 3 of this document*](#authentication-1)).

From the platform's point of view, the process for acquiring an MQTT
token is as follows:

-   Acquire a REST token (yet another kind of authentication token) with
    the appropriate\
    permissions and restrictions via
    https://api.&lt;platform-dns-name&gt;/auth/v0/token. The API
    client's API key is used as the authentication credential for this
    call

-   Acquire an MQTT token with the appropriate permissions and
    restrictions from
    https://api.&lt;platform-dns-name&gt;/datastreams/v0/mqtt/token.\
    The authentication method for this call is passing the
    previously-acquired REST token as a Bearer token in the HTTP
    Authorization header.

This process is ***not*** intended to be implemented in each MQTT client
that connects to the platform. The API key is the master authentication
secret for an API client, and should not be distributed to each external
client.

The intent of this two-step process is to offer the API client
sufficient flexibility to set up its own authentication mechanism for
external clients. Various flows are discussed more in-depth in [*Section
3.1*](#distribution-of-credentials-to-client-devices), titled
Distribution of Credentials to Client Devices.

2.6 Client ID
-------------

As noted in [*Section 3.3*](#mqtt-tokens) of this document, each MQTT
token includes a client ID. This identifier will be used inside the
platform to attribute each published message to a particular MQTT
client.

Of note:

-   This client ID is similar to, but not necessarily the same as the
    MQTT client ID from the MQTT protocol specification. We recommend
    that the token's client ID be reused as the MQTT client ID, but the
    platform does not enforce this as a strict rule.

-   **There can be only one live connection for each client ID**.
    Whenever a connection is set up with a given client ID, the platform
    will terminate any existing connection that uses the same client ID.

2.7 Connection Setup
--------------------

### 2.7.1 Broker Hostname and Port Discovery

The MQTT broker host name can be retrieved from the MQTT token ([*see
Section
3.3.3*](#extracting-broker-endpoint-and-client-id-from-the-token)).

In general though, it is a safe assumption that the host name will be
mqtt.&lt;platform-dns-name&gt; (e.g. mqtt.kpn-dsh.com or
mqtt.staging.kpn-dsh.com).

The broker exposes two connection endpoints:

-   MQTTS (MQTT over TLS) connections on port 8883

-   WSS (MQTT over WebSockets over TLS) connections on port 443

Unsecured (i.e. non-TLS) connections are not supported.

### 2.7.2 MQTT Connection Setup

The MQTT client connection must be configured as follows:

-   Always use TLS. The platform does not support unsecured connections

-   Use a unique MQTT client ID. Recommended, but not mandatory: take
    the client ID as extracted from the MQTT Token

-   Use a random MQTT username. This field is ignored by the broker

-   Use the MQTT Token as MQTT password

### 2.7.3 Example

Using **Mosquitto** ([*https://mosquitto.org*](https://mosquitto.org))
to subscribe to a topic on DSH (mosquitto\_sub will auto-generate an
MQTT client ID if none is supplied on the command line):

mosquitto\_sub -h mqtt.kpn-dsh.com -p 8883 -u xxx -P "\$MQTT\_TOKEN" -t
/tt/weather/1/2/0/2/0/1/0/3/2/1/2/3/0/\#

A more fully fleshed-out example that encompasses MQTT token acquisition
can be found in [*Section 3.3.4*](#examples-2) of this document.

2.8 Ingest Rate Limit
---------------------

All external clients are throttled to an ingest rate (publish rate) of
10 messages per second. In the future, this rate limit will be
configurable on a per-client (or per-MQTT-token) basis.

2.9 Wildcard Publications
-------------------------

Wildcard publication is a proprietary extension to the MQTT protocol. A
wildcard publication is the conceptual mirror image of a standard MQTT
wildcard subscription.

As a reminder, a wildcard ***subscription*** allows clients to subscribe
to an entire topic tree by specifying a topic prefix. All messages
published on topics that have this prefix will be delivered to the
client.

A wildcard ***publication*** allows a publisher to publish a single
message with a topic prefix, which will match all subscription filters
that have the same prefix.

### 2.9.1 Example

Assume a wildcard publication on the topic a/b/\#.

The following subscription filters will match the prefix and receive the
message:

-   a/b (exact prefix match)

-   a/b/\# (wildcard subscription match)

-   a/b/c/d/e (prefix match)

-   a/b/c/d/\# (wildcard subscription match)

The following subscription filters will ***not*** match the prefix, and
hence not receive the message:

-   a (a/b is not a prefix of a)

-   a/\# (a/b is not a prefix of a)

-   a/c (a/b is not a prefix of a/c)

-   a/bb (a/b is not a prefix of a/bb because prefixes are matched
    against entire topic path segments)

### 2.9.2 Rationale

The motivating example for this feature is the distribution of data that
is keyed on geographical position, for example using the **quad key
coordinate system**.
([*https://docs.microsoft.com/en-us/bingmaps/articles/bing-maps-tile-system*](https://docs.microsoft.com/en-us/bingmaps/articles/bing-maps-tile-system))

In such a system, the world is divided into quadrants, and each
additional coordinate subdivides the parent quadrant further. The first
coordinate divides the world as follows:

-   0 is the western hemisphere, north of the equator

-   1 is the eastern hemisphere, north of the equator

-   2 is the western hemisphere, south of the equator

-   3 is the eastern hemisphere, south of the equator

Each subsequent coordinate divides this further:

-   0 is the northwestern quadrant of the parent area

-   1 is the northeastern quadrant of the parent area

-   2 is the southwestern quadrant of the parent area

-   3 is the southeastern quadrant of the parent area

Data providers then publish their information at the applicable level,
with a wildcard publication. For example, data that is relevant to all
of Northern Europe would be published on 1/0/\#.

Data consumers in turn subscribe at the level of detail they are
interested in. For example, a consumer that only cares about the Norse
island of Senja subscribes to 1/0/2/2/3/1/2/1/\#.

The wildcard publication feature ensures that relevant data for all of
Northern Europe is also considered relevant for the more specific
subscription of data for the island of Senja.

### 2.9.3 Limitations

-   Wildcard publications cannot be done over MQTT; they must be
    produced on the data stream from services running within the DSH
    platform.

-   The + wildcard is **not** allowed, only \#.

-   The \# wildcard **must** be the last or next-to-last path segment of
    the publication topic.

The following are ***valid*** wildcard publication patterns:

-   a/\#

-   a/b/c/d/e/\#

-   a/\#/suffix

-   a/b/c/d/e/\#/othersuffix

The following are **invalid** wildcard publication patterns:

-   a/+/b (+ wildcards are not allowed)

-   a/\#/suffix/moresuffix (at most a single level of suffix allowed)

-   a/\#/suffix/ (two suffix levels: suffix and an empty path segment)

### 2.9.4 Mapping of Wildcards to Concrete Topics for Subscribers

When wildcard publications are delivered to an MQTT subscriber, the
message key is expanded to the "minimal match" for the subscription
pattern. This minimal match is constructed according to the following
rules:

-   Path components leading up to the \# character in the message key
    are matched according to the normal MQTT rules

-   Corresponding non-wildcard path components in the subscription
    pattern are transcribed verbatim

-   + wildcards in corresponding path components in the subscription
    pattern are replaced with an empty string

-   A terminating \# wildcard in the subscription pattern is dropped

-   If the message key ends in \#/some-suffix:

    -   If the subscription pattern ends in a wildcard character,
        /some-suffix\
        is appended

    -   If the subscription pattern ends in /some-suffix, nothing is
        appended (the /some-suffix is already there through the
        application of the previous rules)

    -   If the subscription pattern ends in any other literal string,
        there is no match, and the message is not delivered to this
        subscription

The following table shows how various MQTT subscriptions perceive
wildcard publications. The first column shows the message key, the other
columns show how this is translated to a concrete topic for various
subscription patterns.

  ------------------ ------------------ --------------------- ----------------------
  **Wildcard Key**   **SUB(a/b/c/d)**   **SUB(a/b/c/d/\#)**   **SUB(a/b/c/+/+/e)**
  a/b/c/\#           a/b/c/d            a/b/c/d               a/b/c///e
  a/b/c/\#/d         a/b/c/d            a/b/c/d/d             (no match)
  a/b/c/\#/e         (no match)         a/b/c/d/e             a/b/c///e
  a/b/c/d/\#         a/b/c/d            a/b/c/d               a/b/c/d//e
  ------------------ ------------------ --------------------- ----------------------

3 AUTHENTICATION
================

3.1 Distribution of Credentials to Client Devices
-------------------------------------------------

The DSH platform does not keep track of the access rights for individual
devices that connect to the platform over MQTT. Instead, ACLs are
configured on the API client level. API clients that want to further
restrict the access rights for individual devices must set up a
management service of their own to mediate this.

While the DSH authentication mechanism allows for a lot of flexibility
for API clients to set up device access rights, there are two common
models for the distribution of MQTT tokens to devices that connect to
the platform.

### 3.1.1 Full Mediation

In this approach, the device only interacts with the API client's own
authentication service during the acquisition of the MQTT token. The
client authentication service uses the API key to acquire a long-lived
REST token with broad access rights. When the device authenticates to
the client authentication service, the REST token is used to procure a
short-lived MQTT token with restricted access rights for the device.

**Tenant-Driven MQTT Procurement**

![](media/image2.png){width="5.166666666666667in"
height="5.1369160104986875in"}

The main advantage of this configuration is that it allows for more
flexibility. As the device must interact with the API client's
authentication service for each MQTT connection it wants to set up, the
API client can dynamically change permissions on each connection
request.

The main disadvantage is a higher load on the tenant authentication
system.

### 3.1.2 Partial Mediation

In this flow, the device only sporadically connects with the API
client's authentication service to acquire a long-lived, restricted,
REST token that allows it to request *restricted* MQTT tokens from the
DSH platform API directly.

The API client must make sure to properly encode restrictions in the
REST token to prevent abuse, as tokens cannot easily be retracted once
they are distributed.

**Client-Driven MQTT Procurement**

![](media/image3.png){width="6.5in" height="5.027777777777778in"}

The main advantages of this approach are:

-   Reduced load on the API client's authentication system

-   Reduced latency in the MQTT connection setup

The main disadvantage is loss of flexibility. For the lifetime of the
REST token, there is no way to change the device's MQTT access rights.

3.2 REST Tokens
---------------

Only API clients can procure a REST token. Use a POST request on the
/auth/v0/token and pass in the API key (in the apikey header) to request
a token.

The token request can contain a restricted list of authorizations, which
will be encoded in the resulting REST token. If no such list is
provided, the token will grant full access to anything the API client is
allowed to do on the platform.

API clients can then pass tokens on to management services or devices.
The DSH platform will enforce the access restrictions encoded in the
token when the management service or device subsequently interacts with
the platform.

### 3.2.1 Using a REST Token

All APIs that expect a REST token for authentication require it to be
passed along in an Authorization Bearer-type HTTP header.

For example, if the token is 123ABC, all requests should include the
following HTTP header:

> Authorization: Bearer 123ABC

### 3.2.2 Request

  ---------------- --------------------------------
  endpoint         /auth/v0/token
  HTTP method      POST
  authentication   apikey HTTP header
  success return   HTTP 200 OK with token in body
  failure return   any other HTTP status code
  ---------------- --------------------------------

### 3.2.3 Request Body

The request body is a JSON document with the following (informal)
schema:

> RESTTokenRequest ::=
>
> {
>
> "tenant": string, // tenant id
>
> "exp": optional long, // expiration timestamp
>
> "claims": optional Restrictions // authorization restrictions
>
> }
>
> Restrictions ::= Dictionary&lt;string, object&gt; // API endpoint,
> endpoint-specific restrictions

  ----------- -----------------------------------------------------------------
  **Field**   
  tenant      API client ID associated with the API key
  exp         Optional expiration timestamp for the token
  claims      Optional map of API endpoints to restrictions for said endpoint
  ----------- -----------------------------------------------------------------

The exp field defines the expiration date for the token. It is expressed
as a UNIX timestamp (seconds since midnight Jan 1, 1970). There is a
platform-defined maximum token lifetime, currently set at 30 days.
Expiration dates further in the future will be limited to the
platform-defined maximum. If no expiration date is defined, the
platform-defined maximum is applied.

The claims field is an optional map of API endpoints to access
restrictions for that endpoint. The format of the access restriction
specification is specific to each endpoint, and will be discussed in the
documentation of the endpoint itself. If no claims are specified, the
token defaults to the full API client access rights on each API
endpoint.

#### 3.2.3.1 Examples

> // all defaults - maximum expiration date, full access rights
>
> {
>
> "tenant": "foo"
>
> }
>
> // full restriction - allows only to request a restricted MQTT token
>
> {
>
> "tenant": "foo",
>
> "exp": 1498122712,
>
> "claims": {
>
> "datastreams/v0/mqtt/token": {
>
> "id": "just-this-device",
>
> "exp": 1498122700,
>
> "tenant": "foo",
>
> "claims": \[\]
>
> }
>
> }
>
> }

### 3.2.4 Extracting the REST API Endpoint From the Token

As a convenience, the REST API endpoint is encoded in the REST token.
This allows API clients to acquire tokens and distribute them to clients
that have no prior knowledge about the REST API endpoint.

The REST token consists of three parts (header, body and signature)
separated by a \`.\` character. The body of the token is a
Base64-encoded JSON document, from which you can extract the endpoint
field.

In Javascript, you could do it like this:

> var token = /\* ... \*/
>
> var encodedBody = token.split('.')\[1\]
>
> var body = JSON.parse(atob(encodedBody))
>
> console.log(endpoint is \${body.endpoint})

### 3.2.5 Examples

This section gives some concrete examples of the usage of the API.

Request an all-defaults REST token for tenant "foo":

> curl -H "apikey:&lt;foo-api-key&gt;" -X POST --data '{ "tenant": "foo"
> }' https://api.staging.kpn-dsh.com/auth/v0/token

Request a REST token that expires in 5 minutes:

> now=\$(date +%s)
>
> tokenexp=\$(( now + 300 ))
>
> curl -H "apikey:&lt;foo-api-key&gt;" -X POST --data "{
>
> \\"tenant\\": \\"foo\\",
>
> \\"exp\\": \$tokenexp
>
> }" https://api.staging.kpn-dsh.com/auth/v0/token

Request a REST token that allows you to request MQTT tokens with a
maximum lifetime of 5 minutes and client ID "bar":

> curl -H "apikey:&lt;foo-api-key&gt;" -X POST --data '{
>
> "tenant": "foo",
>
> "claims": {
>
> "datastreams/v0/mqtt/token": {
>
> "id": "bar",
>
> "relexp": 300
>
> }
>
> }
>
> }' https://api.staging.kpn-dsh.com/auth/v0/token

3.3 MQTT Tokens
---------------

MQTT tokens for devices are requested from the
/datastreams/v0/mqtt/token endpoint. Access control on this endpoint is
enforced via REST tokens. This allows anyone with a REST token that
holds the appropriate permissions to request an MQTT token. Below, we
will discuss some practical flows for dispensing MQTT tokens to client
devices.

The token request can contain a restricted list of authorizations that
limit the topics a device can publish and/or subscribe to. It also
contains a mandatory client ID the client device must use to connect to
the MQTT broker. The client ID is a free-form string, which the tenant
can use for auditing purposes to correlate a client's actions on the
platform with a real-life user, application or device.

### 3.3.1 Using an MQTT Token

Extract the address of the MQTT broker endpoint and the client ID from
the MQTT token ([*see **Section 3.3.3***
*below*](#extracting-broker-endpoint-and-client-id-from-the-token)), and
upon connection to that broker, pass the token as the connection
password and the client ID as the MQTT client ID.

### 3.3.2 Request

  ---------------- --------------------------------
  endpoint         /datastreams/v0/mqtt/token
  HTTP method      POST
  authentication   REST token
  success return   HTTP 200 OK with token in body
  failure return   Any other HTTP status code
  ---------------- --------------------------------

#### 3.3.2.1 Request Body

The request body is a JSON document with the following (informal)
schema:

> MQTTTokenRequest ::=
>
> {
>
> "tenant": string, // tenant id
>
> "id": string // client id
>
> "exp": optional long, // expiration timestamp
>
> "claims": optional TopicPermissions, // MQTT topic permissions
>
> "dshclc": optional Object // additional client-specific data claims
>
> }
>
> TopicPermissions ::= List&lt;TopicPermission&gt;
>
> TopicPermission ::=
>
> {
>
> "action": "publish"|"subscribe",
>
> "resource": {
>
> "type": "topic",
>
> "stream": string, // data stream name
>
> "prefix": string, // topic prefix
>
> "topic": string // topic pattern
>
> }
>
> }

  ------------------- --------------------------------------------------------------------
  **Request Field**   
  tenant              API client ID
  id                  MQTT client ID that **must** be used when connecting to the broker
  exp                 Optional expiration timestamp for the token
  claims              Optional list of topic permissions
  dshclc              Optional client-specific data claims
  ------------------- --------------------------------------------------------------------

  --------------------------- ----------------------------------------
  **TopicPermission Field**   
  type                        must always be topic
  stream                      data stream name, e.g. weather or ivi
  prefix                      topic prefix, e.g. /tt
  topic                       topic pattern, e.g. +/+/+/something/\#
  --------------------------- ----------------------------------------

The MQTT client id (the id field in the request) may not be longer than
64 characters, and may only contain the following characters:

-   Alphanumeric characters (lowercase and uppercase letters, digits)

-   @, -, \_, . and :

The exp field defines the expiration date for the token. It is expressed
as a UNIX timestamp (seconds since midnight Jan 1, 1970).

The claims field is a list of topic permissions that define what a
client connecting with this token is allowed to do in terms of
subscriptions and publications.

The dshclc (short for "DSH Client Claims") field is a free-form JSON
object that can be specified in the request. This object will be
included verbatim as the dshclc claim in the resulting token. The DSH
platform ignores the contents of this field, but it may be useful for
API clients to communicate some configuration information to the client
devices.

#### 3.3.2.2 Restrictions Encoded in the REST Token

The MQTT token request endpoint allows a set of restrictions to be
encoded in the REST token that limit what the client is allowed to
request.

The structure of these restrictions is very similar to MQTTTokenRequest,
but all fields are optional, and there is an additional field relexp.

The relexp field allows the REST token to express a restriction on the
relative expiration time for the requested MQTT token. Where the exp
restriction states that the requested expiration time in the MQTT token
request may not exceed a specific absolute time, the relexp restriction
states that the requested expiration time in the MQTT token request may
not exceed now + relexp. This allows one to create REST tokens that are
valid for a long time (say, a year) but grant the bearer permission to
request MQTT tokens that are only valid for a short time (say, five
minutes).

Restrictions are enforced as follows:

-   tenant must match exactly

-   id must match exactly

-   exp: granted expiration date will be at most the restricted exp\
    ([*see Section 3.3.3
    below*](#extracting-broker-endpoint-and-client-id-from-the-token))

-   claims: requested topic permissions must be more specific than the
    restricted\
    topic permissions

-   dshclc: the object specified here is merged with the one specified
    in the MQTT token request, with the object specified here taking
    precedence in case of overlapping fields. For example, if the
    restrictions in the REST token set dshclc to {"a": 1, "b": 2} and
    the dshclc field in the MQTT token request specifies dshclc to be
    {"a": 666, "c": 3}, the dshclc claim in the returned MQTT token will
    be {"a": 1, "b": 2, "c": 3}

#### 3.3.2.3 Expiration Time

The expiration date of the MQTT token is influenced by a lot of factors.
In essence, it is the minimum of the following options:

-   Platform-defined maximum expiration date (currently 7 days from now)

-   Expiration date of the REST token

-   Expiration date encoded in the REST token restrictions

-   Now + the relative expiration time encoded in the REST token
    restrictions

-   Expiration date requested in the MQTT token request

#### 3.3.2.4 Topic Patterns

The topic patterns in the claims section describe the kind of
subscriptions a client is allowed to make, as well as the kind of topics
it can publish on.

A concrete publication topic matches a topic pattern if:

-   It starts with &lt;topic-prefix&gt;/&lt;stream-name&gt;/

-   The topic path beyond the prefix has

    -   A concrete path segment (i.e. a string not containing / and
        different from + or \#) for each corresponding + in the topic
        pattern

    -   0 or more concrete path segments for the \# (if any) in the
        topic pattern

    -   The identical concrete path segment for each corresponding
        segment in the topic pattern that is not + or \#

A concrete subscription topic matches a topic pattern if:

-   It starts with the topic prefix, followed by a /

-   The topic path beyond the prefix has

    -   A concrete path segment (i.e. a string not containing / and
        different from + or \#) for each corresponding + in the topic
        pattern

    -   0 or more concrete path segments, + segments and zero or one \#
        segment for the \# (if any) in the topic pattern

    -   The identical concrete path segment for each corresponding
        segment in the topic pattern that is not + or \#

For example, stream weather with prefix /tt and pattern z/+/+/+/\#

-   Matches

    -   For publish:

        -   /tt/weather/z/a/b/c

        -   /tt/weather/z/d/e/f/g/h

    -   For subscribe:

        -   /tt/weather/z/a/b/c

        -   /tt/weather/z/d/e/f/g/h

        -   /tt/weather/z/d/e/f/+/h

        -   /tt/weather/z/d/e/f/\#

-   Does not match

    -   For publish:

        -   /tt/weather/z/a/b

        -   /tt/weather/x/a/b/c

        -   /tt/weather/z/d/e/f/+/h

        -   /tt/weather/z/d/e/f/\#

    -   For subscribe:

        -   /tt/weather/x/a/b/c

        -   /tt/weather/z/a/b/\#

### 3.3.3 Extracting Broker Endpoint and Client ID From the Token

The MQTT token consists of three parts (header, body and signature)
separated by a \`.\` character. The body of the token is a
Base64-encoded JSON document, from which you need to extract the
endpoint and client-id fields.

In Javascript, you could do it like this:

> var token = /\* ... \*/
>
> var encodedBody = token.split('.')\[1\]
>
> var body = JSON.parse(atob(encodedBody))
>
> console.log(endpoint is \${body.endpoint} client ID is
> \${body\['client-id'\]})

### 3.3.4 Examples

This section gives some concrete examples of the usage of the API.

Request an MQTT token without additional restrictions:

> curl -H "Authorization: Bearer \$REST\_TOKEN" -X POST --data '{
>
> "tenant": "foo",
>
> "id": "bar"
>
> }' https://api.staging.kpn-dsh.com/datastreams/v0/mqtt/token

Request an MQTT token that only allows subscribing to a single topic
string:

> curl -H "Authorization: Bearer \$REST\_TOKEN" -X POST --data '{
>
> "tenant": "foo",
>
> "id": "bar",
>
> "claims": \[
>
> { "action": "subscribe",
>
> "resource": {
>
> "type": "topic",
>
> "prefix": "/tt",
>
> "stream": "water",
>
> "topic": "drip/drip/drip"
>
> }
>
> \]
>
> }' https://api.staging.kpn-dsh.com/datastreams/v0/mqtt/token

With this token, the client can connect to the MQTT broker, but will
only be able to subscribe to the literal /tt/water/drip/drip/drip topic.
Any other subscription string (including wildcards) will result in the
broker disconnecting the client.

A shell script that subscribes to an MQTT topic:

> set -eu
>
> usage() {
>
> cat &lt;&lt;EOF
>
> Usage: \$(basename \$0) &lt;tenant&gt; &lt;apikey&gt; &lt;topic&gt;
> \[&lt;platform&gt;\]
>
> The default value for &lt;platform&gt; is dev.kpn-dsh.com.
>
> EOF
>
> exit 1
>
> }
>
> get\_mqtt\_token() {
>
> local tenant="\$1"
>
> local apikey="\$2"
>
> local clientid="\$3"
>
> local platform="\$4"
>
> REST\_TOKEN=\$(curl -sf -XPOST --data "{ \\"tenant\\":
> \\"\$tenant\\"}" -H apikey:\$apikey
> https://api.\$platform/auth/v0/token)
>
> MQTT\_TOKEN=\$(curl -sf -XPOST --data "{ \\"tenant\\": \\"\$tenant\\",
> \\"id\\": \\"\$clientid\\" }" -H "Authorization: Bearer \$REST\_TOKEN"
> https://api.\$platform/datastreams/v0/mqtt/token)
>
> echo \$MQTT\_TOKEN
>
> }
>
> pad4() {
>
> input="\$1"
>
> local len=\$(echo -n \$input | wc -c)
>
> local npad=\$(( (4 - (len % 4)) % 4 ))
>
> local pad=""
>
> for ((i=0; i&lt;\$npad; i++)) ; do pad="\${pad}=" ; done
>
> echo -n "\${input}\${pad}"
>
> }
>
> decode\_jwt\_body() {
>
> local jwt="\$1"
>
> local splits=(\${jwt//./ })
>
> pad4 \${splits\[1\]} | base64 -id
>
> }
>
> if \[ \$\# -lt 3 -o \$\# -gt 4 \] ; then
>
> usage
>
> fi
>
> TENANT="\$1"
>
> APIKEY="\$2"
>
> TOPIC="\$3"
>
> PLATFORM="\${4:-dev.kpn-dsh.com}"
>
> CLIENTID="\$(date | md5sum | cut -c 1-10)"
>
> \# CA certs file has a different location on different systems
>
> if \[ -f /etc/ssl/certs/ca-certificates.crt \] ; then
>
> CACERT=/etc/ssl/certs/ca-certificates.crt
>
> elif \[ -f /usr/local/etc/openssl/cert.pem \] ; then
>
> CACERT=/usr/local/etc/openssl/cert.pem
>
> else
>
> echo "Don't know where to find the trusted CA certificates file on
> your system."
>
> exit 1
>
> fi
>
> MQTT\_TOKEN=\$(get\_mqtt\_token "\$TENANT" "\$APIKEY" "\$CLIENTID"
> "\$PLATFORM")
>
> ENDPOINT=\$(decode\_jwt\_body "\$MQTT\_TOKEN" | jq -r .endpoint)
>
> mosquitto\_sub --cafile "\$CACERT" -d -h "\$ENDPOINT" -p 8883 -u
> "\$CLIENTID" -P "\$MQTT\_TOKEN" -i "\$CLIENTID" -t "\$TOPIC"

4 BEST PRACTICES - MQTT TOKENS
==============================

4.1 Request Tokens with Specialized Claims
------------------------------------------

If no specific restrictions are specified in the MQTT token request, the
resulting token will have all access rights associated with the API
client. This creates a larger potential for abuse. If the token is
leaked, it can be used for more than just its intended use. In addition,
since all access rights are explicitly encoded in the token, a
full-rights token is pretty large. Restricted access rights create
smaller tokens, which saves bandwidth costs.

4.2 Request Tokens with Limited Lifetime
----------------------------------------

By default, an MQTT token has a 7-day lifetime. To prevent abuse, it is
best to request tokens with a limited lifetime, on the order of 5
minutes.

Note that a token must only be valid at connection time; live
connections will ***not*** be terminated when their tokens expire.

4.3 Use Stable Client IDs
-------------------------

When requesting tokens, don't generate throwaway client IDs, but attempt
to retain stable\
client IDs for external clients. This facilitates the attribution of
published messages to\
concrete clients.

4.4 Always Use the Most Recent Token
------------------------------------

It is possible to request multiple tokens for the same client ID with
overlapping lifetimes. As long as the tokens are valid, any one of them
can be used to set up a connection to the platform, although not
concurrently, due to the client ID uniqueness rule ([*See section
2.6*](#client-id)).

In the future, the platform may automatically invalidate existing tokens
for a client ID when a new token for the same client ID is generated. To
be safe, use only the most recent token for each client ID.

5 TROUBLESHOOTING GUIDE
=======================

5.1 Frequently Encountered Issues
---------------------------------

### 5.1.1 My Client Gets Disconnected From MQTT Without Reason

There are two common reasons for the DSH MQTT broker to disconnect a
client abruptly:

-   The client has tried to exceed the access rights granted by its MQTT
    token

-   A new client has connected using an MQTT token with the same Client
    ID

To debug the former, verify that the claims in the MQTT token align with
what the client is trying to do. [*See Section
5.2.1*](#jwt-token-decoder) below for ways to decode the MQTT token.

There are no easy ways for an API client developer to debug the latter
issue; it is up to the API client to ensure the client IDs are unique to
external clients.

### 5.1.2 Connection Attempts are Refused Even Though the MQTT Token Has Not Yet Expired

Valid, non-expired MQTT or REST tokens are sometimes still refused by
the DSH authentication mechanisms. For security reasons, the signing key
for the tokens is kept in memory in the component that generates the
tokens, and is lost if that component restarts for any reason.

The rationale is that it is inexpensive to request a new token, but
costly to deal with a compromised signing key.

If a token has not yet expired, but is still refused, try fetching a
fresh token. If the fresh token is also refused, there is likely an
issue at the client's end (connecting to the wrong platform, the token
gets mangled somehow, etc.).

### 5.1.3 Publishing a Large Amount of Data is Slow, and After a While the Client Disconnects

The ingest rate limit ([*see Section 2.8*](#ingest-rate-limit)) for
external clients is 10 messages per second. Clients publishing at a
higher rate get throttled, which may ultimately result in keepalives
getting throttled as well, which would then result in disconnection
because the broker considers the client to be dead.

5.2 Useful Tools for Debugging
------------------------------

### 5.2.1 JWT Token Decoder

There is a very useful web-based JWT token decoder at jwt.io
([*http://jwt.io*](http://jwt.io)). Simply paste a REST or MQTT token
into that webpage to see the decoded header and body.

### 5.2.2 Manually Set Up MQTT Connections Using Mosquitto

The Mosquitto ([*https://mosquitto.org*](https://mosquitto.org))
command-line tools (mosquitto\_pub and mosquitto\_sub) are very useful
for quick one-off connectivity checks. [*See Section
3.3.4*](#examples-2) for a concrete example of how to use them.

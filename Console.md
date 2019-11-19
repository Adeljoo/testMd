**KPN Data Services Hub (DSH)**

**User Guide**

**Console**

**TABLE OF CONTENTS**

\
=

1 OVERVIEW
==========

The target audience for this document are entities (companies and
individuals) that want to use or contribute to the set of data streams
managed by a Data Services Hub as a tenant.

The Data Services Hub (DSH) Console is a web-based application that
provides a multi-tenant DSH interface to schedule services and manage
DSH resources.

Service management includes:

-   Deploying and managing Docker-based services on the DSH platform.

-   Tracking resource allocation and limits of a tenant's environment
    (such as CPU, memory) and requesting additional resources if needed

2 CONCEPTS
==========

2.1 Multi-tenancy
-----------------

A single instance of the DSH serves multiple tenants. Each tenant (a
group of users) shares common access to specific privileges in the DSH
including, data sharing, services and resources.

The Console ensures that the tenant can only launch containers that
follow a specific set of rules, and prevents tenants from entering other
tenant’s containers.

2.2 Self-serve Container Management
-----------------------------------

The DSH uses the registration engine Ansible. This makes for easy
application configuration and installation on the platform and within
containers. How data and the contents of containers are used is
determined by tenants themselves.

Developers can simply write code and enter it into the DSH’s Source Code
Management system. This system records any changes made to the source
code and then triggers the continuous integration engine, JENKINS. The
JENKINS engine then turns the code into an executable file that is
tested, and if successful, the file is saved in the appropriate storage
location in the DSH containers.

2.3 Containerization
--------------------

Because the DSH offers the ability to work in closed containers, tenants
can operate in the manner and within the standards they prefer, however,
the protocol adapters make it possible to normalize and standardize data
in the DSH messaging platform. Tenants then have the ability to exchange
data with others in a safe and controlled environment.

3 OPENING THE CONSOLE
=====================

The Console is deployed for every DSH platform, and can be accessed via
a web browser. Users authenticate themselves via their own user
credentials and obtain access to DSH resources based on their access
rights.

![](media/image1.png){width="2.8167475940507436in"
height="2.6302088801399823in"}

To open the Console for the target environment in your browser, use :
console.{platform}. For example: console.kpn-dsh.com.

A user can only manage the tenants to which they have access. One user
can manage the resources of multiple tenants.

![](media/image2.png){width="7.235503062117235in"
height="3.1614588801399823in"}

Once you’ve selected a tenant, you get into the following screen where
you can navigate to the different tasks using the menu at the top of the
page.

![](media/image3.png){width="7.046616360454943in"
height="3.651042213473316in"}

4 MANAGE SERVICES
=================

Tenants can manage containers themselves, which gives every tenant the
ability to launch, restart or abort services as needed.

![](media/image4.png){width="6.916406386701662in"
height="3.5468755468066493in"}

4.1 Creating New Service
------------------------

In the top-right-hand corner, there is a button labeled “+ Add New
Service*”*. Simply click the button and another box will appear:

![](media/image5.png){width="4.427083333333333in"
height="2.092450787401575in"}

Enter whatever name you’d like; this is purely for your reference. It is
good practice to title it in a way that describes the service. After you
click “Create Service Draft”, you’ll be taken to a configuration page.

![](media/image6.png){width="6.811919291338583in"
height="3.526042213473316in"}

By default, it contains the following template to help you deploy your
service:

![](media/image7.png){width="7.109375546806649in"
height="2.2450656167979in"}

-   **image:** URL of the container that you want to deploy

-   **cpus:** How many CPUs your container needs

-   **memory:** How much memory you container needs

-   **env:** Any environment variables to be passed into your container

-   **instances:** How many instances you want to be run. Setting to 0
    will create service but stop the container

-   **user:** A user ID that is specific to the tenant that you are
    accessing

More information is available in [***Section 4.3 Service Configuration:
Definition Guide***](#service-configuration-definition-guide).

![](media/image8.png){width="2.5in" height="0.9270833333333334in"}

You can easily edit this .json script and add lines to configure
volumes, vhosts and topics. Later in this document, you can learn how to
request these extra resources.

![](media/image9.png){width="6.546875546806649in"
height="4.151429352580927in"}

You can also edit the script manually where a few additional variables
are available.

![](media/image10.png){width="7.395321522309711in"
height="1.984375546806649in"}

![](media/image11.png){width="1.8854166666666667in" height="0.6875in"}

After you have properly configured your service, you can hit *Deploy* in
the bottom right corner and you will be brought back to your environment
page and should see the new service.

4.2 Service Tasks
-----------------

By choosing a specific service, you get an overview of all the tasks
that are running for this service, with resource metrics, their status
and health. You also get a high-level view of the health of the service.

![](media/image12.png){width="6.928209755030621in"
height="3.2864588801399823in"}

For each task, you can view and/or download the STDOUT and STDERR log
files.![](media/image13.png){width="6.96875in"
height="3.5178783902012247in"}

4.3 Service Configuration: Definition Guide
-------------------------------------------

To deploy a service, you need a service definition that describes the
characteristics of your service. The four main characteristics include:

-   Location of your Docker image

-   Resources required by your service (CPU, memory, vhosts, etc.)

-   A number of environment variables which will be exposed in your
    Docker container

-   How your container behaves (single instance, health check, etc.)

The rest of this guide will discuss how to configure these
characteristics.

### 4.3.1 Configuring the Docker Image

When you deploy your service, you have to specify the location of your
Docker image so the platform knows where to retrieve it. Your Docker
image should always be uploaded to a Docker registry.

{

"image": "xxxxxx-docker.jfrog.io/docker-image-name:1.0.0",

...

}

Only a limited set of Docker registries are allowed for a tenant, as
they are part of a tenant’s limits.

### 4.3.2 Defining Resources

Your service depends on certain resources to work. Some are required,
such as CPU and memory, while others are optional, such as vhosts and
volumes.

#### 4.3.2.1 CPU & Memory

{

"cpus": 0.5,

"mem": 1024,

...

}

The cpu property is defined as shares of one or more CPU cores. A CPU
share provides you with a guaranteed allocation of CPUs. Your service
can spike above this configured value if space is available on the
platform, but will fall back to this minimum allocation when no spare
CPU room is available. Therefore, you should configure this value as
close as possible to the CPU usage required to ensure your service runs
smoothly.

The memory property is expressed in megabytes and strictly represents
the maximum amount of memory for your service. If your service allocates
more memory than configured, it will result in a service restart.

#### 4.3.2.2 Volumes

A volume provides your service with persistent storage, strictly tied to
your service. Picture it as an extra disk you can shove under your
service.

Before you can use a volume, you have to request it via the volumes
management screen. Once assigned, you can use it in your service
definition.

Two options are available to add the volume to your service definition.
Either via the easy-to-use “volumes” drop-down menu in the toolbar, or
by directly editing the service definition.

{

...

"volumes": {

"/data": {

"name": "{ volume('data-volume') }"

}

}

}

In this example, the /data value refers to the path within your
container on which the volume will be available.

To refer to the volume, we use a DSH expression called volume(), in
which you input the name of the volume.

#### 4.3.2.3 Vhosts

Before you can use a vhost, you have to request it via the vhosts
management screen. Once assigned, you can use it in your service
definition.

Two options are available to add the vhost to your service definition.
Either via the easy-to-use “vhosts” drop-down menu in the toolbar, or by
directly editing the service definition.

{

...

"exposedPorts": {

"1880": {

"vhost": "{ vhost('your-vhost-name') }",

"auth": "app-realm:admin:\$1\$EZsDrd93\$7g2osLFOay4.TzDgGo9bF/",

"tls": "auto",

"whitelist": "56.59.120.23"

}

}

}

In this example, the 1880 value is the port within your container to
which all vhost traffic will be directed.

To refer to the vhost, we use a DSH expression called vhost(), in which
you input the name of the vhost. Internally, this vhost expression will
be expanded to a full vhost endpoint, suffixed with the platform domain.

The optional auth property allows you to secure your endpoint with Basic
authentication. When specified, the user will be prompted for a username
and password when trying to access your service via the web. It takes
the form of &lt;realm&gt;:&lt;username&gt;:&lt;password&gt;, where the
password is encrypted with the MD5 based BSD password algorithm 1.

// how to hash the password using MD5 based BSD password algorithm 1 (on
linux or OSX)

&gt; openssl passwd -1 my\_password\_string

\$1\$EZsDrd93\$7g2osLFOay4.TzDgGo9bF/

The optional tls property defines whether your service will be exposed
with a (Let's Encrypt) certificate. The default is auto, indicating that
the port will only accept secure connections. Set this to none if you do
not want the service to have a secure endpoint.

The optional whitelist property allows you to define IP addresses or IP
ranges that can call this service here (for multiple addresses, separate
them with spaces).

### 4.3.3 Specifying Environment Variables

Environment variables allow you to dynamically configure your service.
These variables will be exposed inside your container.

The values within the env object are key/value pairs, where the key is
the name of the environment variable. The values support the use of the
variables() expression.

{

...

"env": {

"TOPIC": "data-stream",

"KAFKA\_BROKERS": "variables('DSH\_KAFKA\_BOOTSTRAP\_SERVERS')"

}

}

### 4.3.4 Specifying Container Behaviour

#### 4.3.4.1 Number of Instances

You can scale your service to one or more instances by specifying the
instances property:

{

...

"instances": 2

}

#### 4.3.4.2 Container User

For security reasons, the DSH platform enforces the use of a
tenant-specific user within the container. Make sure your container
image uses the same user. You can specify this user with the user
property:

{

...

"user": "xxxx:xxxx"

}

#### 4.3.4.3 Single Instance Behaviour

The singleInstance property, when true, marks your instance as “not able
to scale”. If not set when upgrading an application, we will first spin
up a new instance. When that is up, deactivate the old instance.

{

...

"singleInstance": true

}

#### 4.3.4.4 Kafka Connectivity

If your service requires a connection with Kafka, it will need a DSH
Kafka token. This will be provided to your service as the
DSH\_SECRET\_TOKEN environment variable when you toggle the needsToken
property to true:

{

...

"needsToken": true

}

#### 4.3.4.5 Service Health Check

It's considered a best practice to define an HTTP Health Check endpoint
in your service, which will be verified by the platform. When the
endpoint returns a *200 OK* result, the service is healthy. You can let
the platform know where the health check endpoint can be accessed like
this:

{

...

"healthCheck": {

"protocol": "http",

"port": 8080,

"path": "/health"

}

}

#### 4.3.4.6 Variable Expressions

Service definitions support the use of a predefined set of variables:

-   DSH\_KAFKA\_BOOTSTRAP\_SERVERS: A comma-separated list of Kafka
    brokers, which you can use in your Kafka consumer/producer

-   DSH\_ENVIRONMENT: Uniquely defines the DSH environment on which the
    service is running

-   DSH\_TENANT: Name of your tenant

These variables can be used by using the variables() expression:

{

...

"env": {

"KAFKA\_BROKERS": "variables('DSH\_KAFKA\_BOOTSTRAP\_SERVERS')"

}

}

**Inspect deployed services:** view their logs, their current app
definition, deployment status.

5 REQUEST MORE RESOURCES
========================

Console can be used to request extra resources:

-   CPU

-   Memory

-   Volumes (network attached storage)

-   Vhosts (virtual host, exposes HTTP service through DSH's reverse
    proxy)

-   Topics

5.1 CPU & Memory
----------------

At the top of your environment, there are two “+” boxes next to CPU and
Mem status bars. If you need more or less CPU or memory, simply click
the corresponding box.

![](media/image14.png){width="6.5in" height="0.34375in"}

CPU shows the CPUs assigned to the tenant and allows you to request for
an increase. This action always requires manual approval by a site
reliability engineer (SRE). This applies to all limits. Limits are never
automatically applied (when requested through the Console).

Memory shows the total memory assigned to the tenant and allows you to
request an increase.

The request will be picked up by the [***Platform Management
Portal***](https://drive.google.com/a/klarrio.com/open?id=1pTJuyL4218sjxKgQARLPyU5tVIidOs4mVJLUaC_VveM)
and requires manual approval by the DSH platform administrator.

The “CPU +” will bring up the following text box:

![](media/image15.png){width="2.776042213473316in"
height="2.804368985126859in"}

Here you can input the **total amount of cores for the environment**
requested, as well as add any comments or reasons to add more cores.

After you click “Request”, you may see the following image show up next
to the CPU utilization, this means that your request has been sent, and
is awaiting approval by a system administrator.

![](media/image16.png){width="6.5in" height="0.4270833333333333in"}

The memory request works in the same way as the CPU request. It is again
important to note that you should input the **Total amount of memory for
the environment**.

![](media/image17.png){width="3.53125in" height="3.488290682414698in"}

5.2 Volumes
-----------

Volumes provide extra disk storage to your service, which will be
mounted on a certain path in your container.

Here you have an overview of your available and requested volumes. To
use a volume you have to configure it in the service's definition.

![](media/image18.png){width="7.064811898512686in"
height="2.088542213473316in"}

Here you can request a new volume which you can attach to a service.

After you click “Request Volume”, the new volume is immediately created
(if the volume limit is not exceeded).

![](media/image19.png){width="6.75in" height="2.8645833333333335in"}

![](media/image20.png){width="6.5in" height="0.8854166666666666in"}

![](media/image21.png){width="6.5in" height="0.5104166666666666in"}

5.3 Vhosts 
-----------

Vhosts provide you with a URL to access web-based interfaces exposed by
your containers. To use a vhost, you must first configure it in the
service's definition.

![](media/image22.png){width="6.95in" height="3.619792213473316in"}

Request a new vhost which, once provisioned, you can use in your service
definitions to expose your web-based interfaces via a URL. A vhost
request requires manual approval by the DSH platform administrator.

![](media/image23.png){width="6.955313867016623in"
height="2.307292213473316in"}

5.4 Topics
----------

A tenant can also create Kafka topics that can only be seen by the
tenant’s own containers. It will not be available for other tenants or
over MQTT. No approval is necessary for these topics, and they are
immediately created after the request (if the limits on \# of topics or
\# of partitions are not surpassed).

The platform will namespace the topics to make them unique within the
platform. Once created, they will have the following naming:
scratch.&lt;stream-name&gt;.&lt;tenant&gt;

Eg. Based on the screenshot below you have the following topics:
scratch.chaos-pecos.dshtest & scratch.testtopic.dshtest

![](media/image24.png){width="6.943872484689414in"
height="3.5989588801399823in"}

When creating a new data stream, the following info should be provided:

1.  The stream name

2.  The number of stream partitions. This defines the stream
    parallelism: each tenant application reading from the stream can
    have up to this number of instances to process messages in parallel

3.  The replication factor: How many times the stream will be replicated
    for resilience. This is limited to the number of Kafka brokers

In order to optimize the use of these topics, some Kafka topic-level
configurations are used when creating the Kafka topics.

### 5.4.1 1-Day Retention vs. Log Compaction

To clean the Kafka log, old log data should be discarded.

On the DSH you have 2 options:

-   **1-Day Retention:** Old records are removed after a fixed period of
    time (one day). This works well for temporal event data such as
    logging where each record stands alone

-   With **Log Compacted Topics**, Kafka removes any old records when
    there is a newer version of it with the same key in the partition
    log. This way the log is guaranteed to have at least the last state
    for each unique key forever

### 5.4.2 Broker Timestamps vs Producer Timestamps

On a Kafka topic, each message contains a metadata timestamp attribute.
You can configure it here, and this timestamp is set by:

-   The producer on message creation time

-   The broker on message insertion time

### 5.4.3 Max Message Size

Max message size is important if you want to push larger messages over
Kafka.

### 5.4.4 Segment Size

Segment size impacts the amount of control over
retention.![](media/image25.png){width="7.078125546806649in"
height="3.6298075240594927in"}

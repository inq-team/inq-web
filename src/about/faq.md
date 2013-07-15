---
layout: base
title: FAQ
in_menu: true
description: Frequently asked questions about Inquisitor Linux hardware testing and monitoring platform
keywords: faq,frequently,asked,questions,Inquisitor,linux,hardware,testing,monitoring,certification
sort_info: 90
---
# Frequently asked questions

## Why it is called Inquisitor?

This name originates from 2004, when ALT Linux was building its new
installer/configuration system. All its components' names finished with
<code>*tor</code> (i.e. <a href="http://freesource.info/wiki/Musorka/AltLinux/Sisyphus/Separator">separator</a>,
<a href="http://sisyphus.ru/srpm/propagator">propagator</a>, predator,
<a href="http://freesource.info/wiki/AltLinux/Sisyphus/Alterator">alterator</a>,
etc). Mikhail Yakshin came forward with a curious idea of calling new hardware
testing system an "Inquisitor" -- it fitted <code>*tor</code> schema perfectly
and besides, it was a pun on system's functionality with stress tests
like *cpuburn*.

There's <a href="http://lists.altlinux.org/pipermail/devel-conf/2004-February/003069.html">a
message in ALT Linux devel-conf mailing list</a> that started it all :)

## Is Inquisitor a Linux distribution or what?

Well, yes and no. Inquisitor is somewhat you might call
meta-distribution. Sure, it boasts separate Live CD that one can
download and use, just as one might download any other Live CD Linux
distribution, and Inquisitor can be built into bootable root that would
look just like real Linux system (but customized for specific tasks).

However, Inquisitor does not have its own separate package repository.
This is done purely by intent, there are several strong reasons to do
so:

* There are some great and well-maintained repositories already
available. These repositories usually have 95% of software we'd need to
build complete Inquisitor system. It's just a huge waste of time and
effort to make yet-another-repository and rebuild everything.

* There are some industry standard distributions that most people
recognize and would like to use. If we'd built our own kernel, for
example, failing or passing of hardware on that kernel would mean very
little: it could be a bug in our kernel build and userbase is very
narrow to test it properly on huge range of hardware. Instead, if we'll
use, for example, some wide-spread kernel, such as one from ALT Linux,
Debian, Gentoo, Red Hat, SuSE or Ubuntu. Same logic is applicable to all
other software in the repository.

* An ability to build Inquisitor on top of multiple distributions gives
it an unique feature: it's possible to compare various
distributions/repositories -- in terms of hardware support, performance,
stability, etc. For example, one could easily compare performance of
video card X on various distributions and choose the fastest one.

## Is it correct the web framework requires an LDAP server to authenticate?

Web framework uses standard Ruby on Rails modular authentication scheme
that allows to plug in just about anything possible as an authentication
source. By default, we're using LDAP connection to Microsoft's
ActiveDirectory. It doesn't any any MS-specific fields and should work
with just about any LDAP source that stores users and can authenticate
their passwords. All roles and security data is stored in a table.

## How to disable authorization in Web interface?

It's better to switch authorization to SQL table based one, adding
something like a password in SQL user's table schema.

The quick'n'dirty way is to change
/server/web/app/controllers/account_controller.rb -- find a "def
authenticate(login, password)" method there. It returns a Person object
from user's table in database (named "people"), so you can short-circuit
the checks there to return always some user without real LDAP checks.

## Where do the scanner A P S T and C variable stand for, considering the scanner?

Scanner daemon is really required only if you have a barcode scanner and
want to do some high-level automation of database entry. Using a
scanner, you can automate:

* entry of assembler, tester and shelf IDs

* logging of computer-related stages performed manually (i.e., in a
manufacturing, you'd want to log assembly, testing, packing, etc,
separately, for later analysis and statistics)

These codes (A P S T C), etc, all match starts of particular barcodes
(i.e. a test operator can log his activities using a scanner -- he scans
his badge with something like "T123" on it -- and then the scanner daemon
knows that it's a test operator working with scanner).

## Do I need to configure additional IP ranges for the shelves?

IP ranges and shelf locations are a pretty complex thing. IP ranges and
shelf locations currently require managed switches that can assign a
VLAN for a range of ports that are physically routed to a particular
shelf. You program your switches in a way that you have a VLAN for every
single shelf, then plug a server into a trunk, create an VLAN interface
in server's configuration (one interface per one VLAN = one shelf), and,
bingo, you can get an information about where is your computer under
test by its IP net. Then you have to write these ranges down into
application server's shelf configuration and finally you'll get a nice
grid with all your shelf locations.

## How to create a new order?

Sadly, there's currently no way to create order manually from web UI. In
all systems that we've implemented it was not necessary: the orders were
instantiated inside Inquisitor from some external means, i.e. via
conversion from some external ERP system. This way some managers create
an order in their system => Our special conversion script takes ERP's
order and transfers it into Inquisitor => Inquisitor then tracks this
order => Computers are created from that order => Computers are tested
=> Everything's done => Another conversion script transfers data about
order completion back to ERP system.

The simplest way you can go now is the manual creation of orders using
SQL. Just use something like:

<pre>
INSERT INTO orders (order_id) VALUES (1);
INSERT INTO order_stages (order_id, stage, start, end) VALUES (1, 'ordering', NOW(), NOW());
INSERT INTO order_stages (order_id, stage, start, end) VALUES (1, 'warehouse', NOW(), NOW());
INSERT INTO order_stages (order_id, stage, start, end) VALUES (1, 'acceptance', NOW(), NULL);
</pre>

And then you should go to /orders/show/1 and you'll see "create
computers" panel there.

Alternatively, and the most straightforward way, you can just ditch the
whole "orders" thing and go straight to computers. Just create whatever
computers you want, like that:

<pre>
INSERT INTO computers (id) VALUES (1);
</pre>

And then you can go to /computers/show/1 and behold that one.

## How does computer know it's ID?

Well, you've done all the job of server manually. Let me try to explain
whole ID process. It goes like that:

1. Computer under test boots, fails to find ID by MAC identification and
asks for manual ID entry from keyboard.

2. You enter ID.

3. Computer under test memorizes that ID in RAM (or RAM disk, which is
the same RAM). It will use it thoroughly, but if you'll reboot it in any
way, the ID would be lost and you'll have to re-enter it on boot, so
there comes next step...

4. Computer under test detects its own hardware (including network
adapters and MAC numbers) and submits it all to the server
(submit_components).

5. Server makes clever checks and determines if this a continuation of
previous testing of the same computer or it's new testing. If our case,
computer under test is first-timer, so the decision is easy: it's a new
testing.

6. Server creates new "testing" for computer under test, adding a row
into "testings" SQL table and memorizes hardware configuration of that
testing in components. New component_models, etc, are created
automatically and linked to, if needed.

7. After that, when the server has memorized all hardware components
(including NIC MACs) properly, you can reboot your computer under test
as much as you want. It'll get its ID now from MAC identification,
issuing a query to server like "tell me, what ID is for computer with
MACs like that", and server will gladly tell it back it's proper
computer ID.

So, you've done step #6 manually, doing all that pesky SQL queries to
insert components, component_models and other stuff like that by hand.
It's something wrong with steps #1-5, so I'd advise to check them all
step-by-step and find by it fails to work properly somewhere in between.

## What is computer ID?

Computer ID is a simple integer counter, counting from 1 up. If you've
created computer manually by inserting a row into computers, then you've
inserted ID value with that row. It has nothing in common with MAC for
example.

## What exactly is the deal with features upon creation of a profile?

The thing is simple: each profile is a collection of tests described in
XML document _AND_ some metadata (model, features) which aid proper
selection of profile. If you'll use creation of computers from orders,
you'll have to select:

* model for a computer (one from models table) => this one is stored in
computers.model_id field

* profile for a computer (cleverly selected from a list)

The magic is in step 2, where you select a profile from a list. The
list is not a full list of all profiles available in the system, it's
cleverly filtered and sorted in a following way: you get only profiles
that have either NULL in model_id field, or the same model_id as the
computer you create. "Features" is a string label for profile, and it
can either NULL (=regular testing profile) or contain some label, which
designates some "special" profile with unique qualities. You can select
these "special" profiles manually, they won't be selected by default.

Bottom line:

* Use model_id in profile if you want to create a profile specific for
particular model and use it by default on that model, instead of regular
common profile.

* Use features in profile if you want to create a very specific profile
suited for particular task (i.e. "benchmarking", "servicing", "extremely
hard test"), etc. It's guaranteed that this profile won't be selected by
default, so you won't run any "special" profile accidentally.

## What is model used for? Is this to bind tests to a certain model?

"Models" is a simple dictionary, ID <-> name. You can access a simple
editor for models by accessing http://127.0.0.1:3000/models/ (it's very
crude scaffolding, so it's sort of hidden) or you can just insert string
you need in SQL table "models".

Also, note that there are 2 distinct profile_id settings:

* computers.profile_id contains a profile for computer; it
doesn't mean anything by itself -- it's just a setting stored in a
database. You can adjust this profile using web interface of computer at
any time (given that you have sufficient rights to edit it). It will
"materialize" itself as testings.profile_id (it will be copied there)
when the test would start.

* testings.profile_id is meaningful. It's read-only field that stored a
completed fact -- that this particular testing of this computer went
using some sort of profile. This way we're permanently storing an
explanation, why these tests were ran and what parameters have they
used.

It you're editing computers.profile_id -- you're always changing the
profile for future testings. It won't change any past or current
testings' profile on fly, they are permanently stored
testings.profile_id.

## What is "images directory" / IMAGE_DIR (in config file)?

Images directory works pretty simple and straightforward. "Tarball" is a
convenient form of storing/delivering lots of files as one, with full
information about paths (absolute paths in our case).

For example, you want some files to turn up in /usr/share/inquisitor.
You do a directory structure like that:

<pre>
SOME-TEMPORARY-DIRECTORY/usr/share/inquisitor/
</pre>

and place files, say, "foo" and "bar", at

<pre>
SOME-TEMPORARY-DIRECTORY/usr/share/inquisitor/foo
SOME-TEMPORARY-DIRECTORY/usr/share/inquisitor/bar
</pre>

Then all you have to do is run something like:

<pre>
% cd SOME-TEMPORARY-DIRECTORY
% tar -cvzf BUILD-DIR/images/my-files.tar.gz
./
./usr/
./usr/share/
./usr/share/inquisitor/
./usr/share/inquisitor/foo
./usr/share/inquisitor/bar
</pre>

After that, you'll get "my-files.tar.gz" tarball in images directory in
BUILD-DIR. Untarring of such a file in build process would result in
files delivered to the right place. You are free to pack whatever
absolute paths you want to in a tarball and you're free to use as many
tarballs as you want. In fact, it's the easiest and simplest form of
software packaging (i.e. Slackware distro, AFAIK, still uses simple
tarballs for distribution of its software) -- thus we've decided it would
be.

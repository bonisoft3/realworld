# RealWorld

Pronto's oracle for a complete application contract, implementing Conduit from
[RealWorld](https://github.com/gothinkster/realworld). People publish articles,
follow authors, favorite articles, comment, and read feeds. The familiar
external contract provides a reference for behavior; the app's visual identity
is its own.

It exercises **identity and forms → authenticated API → permissions and
persistent writes → reactive reads → joined screens**. The important boundaries
are ownership, visibility, relationships, validation failures, and whether a
successful mutation produces the correct article, feed, profile, and comment
views.

This is the broad integration oracle among the apps: correctness must survive
the journey between client and server, including attempts by the wrong user.
Upstream behavior and Pronto-specific extensions such as reactive refresh
should be identified separately, so a local extension does not silently change
what it means to conform to RealWorld.

The [[ir.html|application design]] describes the implemented behavior, and
[[DESIGN.md|visual design]] describes the authored presentation.

See [[docs/index|documentation]] for Cloudflare release setup.

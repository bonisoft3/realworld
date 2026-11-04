---
pronto: alpha
name: realworld
business: a public social blogging community, the RealWorld "Conduit" spec on pronto
stage: public social app, released on Cloudflare
team: studio
cluster: mecha
terminal: omnishell
loop: sayt
build: bayt
---

# Conduit

A place to read and write, in public. Someone comes in, reads what the community has posted, follows the writers worth following, and, when they have something to say, writes it themselves. Everything written here is public to everyone in it, and everything done about it (writing, following, favoriting, commenting) belongs to a person.

## People

- A person signs in with a **passkey**, as a **guest**, or through **Google**; Conduit gives them a friendly **handle**, and no two people share one.
- What belongs to a person is what they did: their articles, their comments, their follows, their favorites, their own profile. Only the author of an article may change or remove it, only a comment's writer may remove it, and only a person may edit their own profile.
- Every person has a **public page**: their handle, a **display name** they may set, a line **about** themselves, and a **picture**.

## Data

- [[Article]]: title, one-line description, markdown body, tags, readable address, author, and timestamps.
- [[TagCount]] and [[ArticleStats]]: derived live counts of popular tags and article favorites.
- [[Favorite]], [[Follow]], [[Comment]]: per-person actions over community articles and writers.

## Screens

- **Home** (`/`): masthead, community feed, personal feed of followed writers, popular tags, and search.
- **Article**, **Editor**, **Profile**, **Settings**, **Tag**, **Search**, and **Reading List**.

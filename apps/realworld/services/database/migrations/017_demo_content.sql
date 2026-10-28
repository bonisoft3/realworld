SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

WITH authors AS (
  INSERT INTO app_user (id, handle, display_name, bio)
  VALUES
    ('d3a00001-0000-4000-8000-000000000001', 'mira-demo', 'Mira Sol', 'Fictional writer collecting small stories about places and the people who make them.'),
    ('d3a00002-0000-4000-8000-000000000002', 'theo-demo', 'Theo Vale', 'Fictional maker, reader, and enthusiastic observer of everyday rituals.'),
    ('d3a00003-0000-4000-8000-000000000003', 'nia-demo', 'Nia Hart', 'Fictional photographer and walker with a soft spot for the long way home.')
  ON CONFLICT DO NOTHING
  RETURNING id
), pieces (id, author_id, title, description, body, tags, cover_url, cover_credit, age) AS (
  VALUES
    ('d3b00001-0000-4000-8000-000000000001'::uuid, 'd3a00001-0000-4000-8000-000000000001'::uuid,
     'A little more room for wonder', 'On taking the long way through the woods, and noticing what was there all along.',
     $body$The path begins behind the last house on the street. For years I walked past it with a list in my head and somewhere else to be. One morning, with no particular plan, I turned in.

The woods were doing what woods do: holding the cool air, catching the light, making a great deal out of very little. A fern had unfolded beside the path. A bird called once, then again from farther away. I stood still long enough to hear my own footsteps stop.

## An invitation to look closer

I used to think wonder required a distant place or a free afternoon. Lately I have been practicing a smaller version:

- Take a familiar route at an unfamiliar pace.
- Notice one thing that has changed since yesterday.
- Leave enough space in the day to follow a little curiosity.

> Attention is a way of making room for the world.

I came home with muddy shoes and no grand revelation. The day felt larger anyway.$body$,
     'nature, slow-living, reflection', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1200&q=80', 'Photo via Unsplash', interval '1 day'),
    ('d3b00002-0000-4000-8000-000000000002'::uuid, 'd3a00002-0000-4000-8000-000000000002'::uuid,
     'The quiet ceremony of making coffee', 'A few minutes at the kitchen counter can become a generous beginning.',
     $body$Before the messages and the meetings, there is the sound of water heating. I grind the beans, open the window, and wait for the room to fill with that unmistakable warm, nutty smell.

There is nothing elaborate about my coffee. The cup is chipped; the recipe changes with whatever beans are in the cupboard. What matters is the pause. It gives the morning a threshold instead of a starting gun.

## Make it your own

You might prefer tea, a glass of cold water, or breakfast eaten sitting down. Choose something ordinary and give it your full attention for five minutes. Let the little ritual be useful because it feels good, not because it makes you more productive.

Some mornings I still rush. On the others, I carry the cup to the window and watch the street wake up. That is enough of a plan.$body$,
     'rituals, food, slow-living', 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200&q=80', 'Photo via Unsplash', interval '2 days'),
    ('d3b00003-0000-4000-8000-000000000003'::uuid, 'd3a00003-0000-4000-8000-000000000003'::uuid,
     'Postcards from the edge of the lake', 'A notebook, a changing sky, and the pleasure of staying in one place.',
     $body$We arrived at the lake before the clouds had made up their minds. The water held a pale reflection of the hills, interrupted only by the widening circles left by a fish.

I had packed a camera and a notebook, intending to bring back evidence of the trip. Instead I spent most of the afternoon sitting on a flat stone. The view kept changing without asking me to move: shadows crossed the slope, the wind combed the water, and a patch of blue appeared over the far shore.

## A postcard to remember it by

*Dear future self,*

You do not have to fill every hour to have a good day. Bring a sweater. Stay until the light changes. Say yes when someone offers you the last orange.

*Love, the person on the stone*

The photographs are lovely, but that little note is the souvenir I keep returning to.$body$,
     'travel, nature, photography', 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?w=1200&q=80', 'Photo via Unsplash', interval '3 days'),
    ('d3b00004-0000-4000-8000-000000000004'::uuid, 'd3a00001-0000-4000-8000-000000000001'::uuid,
     'A notebook for unfinished things', 'Why the best ideas sometimes need a place to be imperfect.',
     $body$My favorite notebook is not the beautiful one on the shelf. It is the one with a bent cover, crossed-out sentences, and a page where a grocery list sits beside a sketch of a chair.

For a long time I saved the first page of a new notebook for something worthy. That meant the notebook stayed empty. Eventually I began in the middle, with a question I could not answer. The blank pages became less intimidating once one of them was already a mess.

## A gentler practice

Write down fragments. Draw badly. Record a sentence you overheard or a color you want to remember. Return when you feel like it, and let the pages hold ideas that have not yet found their shape.

A notebook does not need to be an archive of finished work. It can be a place where curiosity has somewhere to land.$body$,
     'creativity, writing, rituals', 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=1200&q=80', 'Photo via Unsplash', interval '4 days'),
    ('d3b00005-0000-4000-8000-000000000005'::uuid, 'd3a00002-0000-4000-8000-000000000002'::uuid,
     'The books we pass along', 'A small case for lending a favorite book and leaving a note inside.',
     $body$A friend once handed me a novel with a train ticket tucked between its pages. On the back she had written, “This is where I was when I read the ending.” I kept the ticket in place and added a note of my own before passing the book along.

Books gather histories beyond the stories printed in them. A softened spine, a penciled star, a receipt from a long-closed shop: each is evidence that someone carried the same world for a while.

## Start a little chain

Pick a book you loved and offer it to someone who might love it differently. Add a note about a sentence, a character, or simply where you were when you read it. Ask them to add their own before it travels on.

There is no need to track its journey. The gift is in imagining all the hands it might find.$body$,
     'books, community, creativity', 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=1200&q=80', 'Photo via Unsplash', interval '5 days'),
    ('d3b00006-0000-4000-8000-000000000006'::uuid, 'd3a00003-0000-4000-8000-000000000003'::uuid,
     'Chasing the last light', 'A reminder that a good walk does not need a destination.',
     $body$The best part of an evening walk is the moment the familiar becomes briefly unfamiliar. Windows glow. Long shadows reach across the pavement. The same corner shop looks like a scene from a film you almost remember.

I started bringing my camera along, then realized I was spending more time looking for a picture than looking around. Now I take one photograph, if something catches my eye, and put it away again.

## A small field guide

Look for the warm light on a wall, the shape of a tree against the sky, or the way a neighbor has arranged plants by the door. If you meet a friend, walk together for a block. If you find a bench, sit on it.

The route can be short. The point is to arrive home with a little more of the day than you had when you left.$body$,
     'photography, walking, slow-living', 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200&q=80', 'Photo via Unsplash', interval '6 days')
)
INSERT INTO article (id, author_id, title, description, body, tags, cover_url, cover_credit, created_at, updated_at)
SELECT pieces.id, pieces.author_id, title, description, body, tags, cover_url, cover_credit, now() - age, now() - age
FROM pieces JOIN authors ON authors.id = pieces.author_id
ON CONFLICT DO NOTHING;

COMMIT;

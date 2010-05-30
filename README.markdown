Housefire
=========

I work with a bunch of guys who like to stomp on lighthouse tickets all the
live long day. We needed a way to keep track of who was working on what
ticket. We like campfire.

Most importantly, housefire just seemed like an awesome name for a gem.

Create a ~/.housefire file with some info about your LH account and your
campfire account.

		#required config:
  	lhuser: <your lh login>
  	lhpass: <your lh password>
  	account: <your campfire domain>
  	token: <your campfire auth token>
  	room: <the campfire room to talk to>
  	# optional config:
  	ssl: <use ssl for campfire, defaults to false>
  	lhcache: <where to put the lighthouse event cache, defaults to ~/.housefire.tmp>

Then, start up housefire and just leave it running. It currently checks LH
every 60 seconds and keeps a local cache of what it has previously seen to
keep the spam down on campfire.

TODO:
- don't let the cache grow ad infinitum, only cache the last few dozen events
- better formatting for specific events
- cowsay?
- better control over verbosity
- xmpp support



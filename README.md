TV Bumble

My second project for GA WDI.  I used Ruby, Sinatra, Postgresql and HTML to create an app for my friends to share their favorite tv shows with each other.  Currently a work in progress, as I want to add more features, and I had issues with losing code.  I didn't get as far as I wanted to in the time I had.

My friends are constantly sharing their favorite tv shows on our Slack channel, but the list can get quite long, and you can never remember how long ago someone recommended a certain show that you now want to watch.  So I created this app where you can log in, search for a show, and rate it.  It then appears on your homepage in your collection, and you can go to your friend's collections, to see which shows they've liked.

I started by creating the databases and choosing an API to get the tv show data from.  As soon as you indicate that you've watched a show, it gets loaded into the local database, so the next time someone searches for that show, there is a quicker load time.  I also added a rating system, and the TV shows you've rated are sorted by rating on your homepage.

I also had to create a list of the TV show collections that every other user has, and list those shows when you click on their name.  As the users are currently only a few of my friends, this feature will need to be refactored if more people sign up.  I will also need to add a feature to create an account, as currently you are only able to log in.

Features I would like to add in the future: click on the image of the show to be taken to the information page, reformat the way users are displayed and display each user's name above their collection, ensure that if a show has already been added to the database, it cannot be added again, and add more styling.

My app has been deployed on Heroku, and you can see it here.

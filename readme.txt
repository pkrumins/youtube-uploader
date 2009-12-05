This is a YouTube video uploader that works without any APIs. It just
simulates what a browser would do and takes all the steps to post the video
and set the video info.

It was written by Peteris Krumins (peter@catonmat.net).
His blog is at http://www.catonmat.net  --  good coders code, great reuse.

The code is licensed under the GPL license.

The code was written as a part of the article "How to Upload YouTube Videos
Programmatically" on my website. It's written in a tutorial style with
careful explanations of how the uploader works. Read the article here:

 http://www.catonmat.net/blog/how-to-upload-youtube-videos-programmatically/

------------------------------------------------------------------------------

How to use this program?
------------------------

The program is called "ytup.pl", short for "youtube upload". If you run it
without arguments, it will output its usage pattern:

    $ ./ytup.pl 
    Usage: ./ytup.pl -l [login]
                     -p [password]
                     -f <video file>
                     -c <category>
                     -t <title>
                     -d <description>
                     -x <comma, separated, tags>

Since YouTube is now part of Google services, you may specify your Google
login and password to -l and -p arguments.

If you don't want to expose your login and password as command line arguments,
you can also set them in the program as YT_LOGIN and YT_PASS constants.

-f is the path to video file, it can be relative path or absolute path, for
example, -f /home/pkrumins/video.avi. If the path to video contains spaces,
quote the video argument like this, -f "my video.avi".

-c is the category number you want your video to be classified in (see below
for all the possible categories). For example, "-c 10" would set category as
"Music".

-t is the title of the video. For example, -t "My cat video". You have to
quote the title.

-d is the description of the video. For example -d "My cat sleeping on a
couch". You have to use quotes around the description.

-x is a comma separated of tags. For example -x "cat, peteris, couch, sun".
Tags also have to be quotes.

Here is the list of possible categories (for -c switch):
    2    - Autos & Vehicles
    23   - Comedy
    27   - Education
    24   - Entertainment
    1    - Film & Animation
    20   - Gaming
    26   - Howto & Style
    10   - Music
    25   - News & Politics
    29   - Nonprofits & Activism
    22   - People & Blogs
    15   - Pets & Animals
    28   - Science & Technology
    17   - Sports
    19   - Travel & Places

Here is an example usage of the program:

    $ ./ytup.pl -l 'my_login@gmail.com' -p 'my_password' -f ./videoclip.avi
                -c 2 -t "Auto race video" -d "Nascar auto race"
                -x "car, auto, nascar, race"

    Logging in to YouTube...
    Uploading the video (foo)...
    Done!


------------------------------------------------------------------------------

Have fun uploading your videos!

Sincerely,
Peteris Krumins
http://www.catonmat.net


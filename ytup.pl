#!/usr/bin/perl 
#
# Version 1.0: 2007.07.30
# Version 1.1: 2007.10.12: youtube changed html
# Version 1.2: 2008.03.13: youtube changed html
# Version 1.3: 2009.12.02: youtube changed html and now logins with google login
#
# Peteris Krumins (peter@catonmat.net)
# http://www.catonmat.net  --  good coders code, great reuse
#
$|=1;

use constant VERSION => "1.3";

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD++;
use HTML::Entities 'decode_entities';

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

# debug?
use constant DEBUG => 0;

# set these values for default -l (login) and -p (pass) values
#
use constant YT_LOGIN => "";
use constant YT_PASS  => "";

# video categories
#
my %cats = (
    2   =>  'Autos & Vehicles',
    23  =>  'Comedy',
    27  =>  'Education',
    24  =>  'Entertainment',
    1   =>  'Film & Animation',
    20  =>  'Gaming',
    26  =>  'Howto & Style',
    10  =>  'Music',
    25  =>  'News & Politics',
    29  =>  'Nonprofits & Activism',
    22  =>  'People & Blogs',
    15  =>  'Pets & Animals',
    28  =>  'Science & Technology',
    17  =>  'Sports',
    19  =>  'Travel & Places'
);

# various urls
my $login_url      = 'http://www.youtube.com/login';
my $login_post_url = 'https://www.google.com/accounts/ServiceLoginAuth?service=youtube';
my $login_cont_url = 'http://www.youtube.com/';
my $upload_url     = 'http://upload.youtube.com/my_videos_upload?restrict=html_form';
my $upload_video_url1 = 'http://www.youtube.com/gen_204?a=multi_up_queue&si=%SI%&uk=%UK%&ac=1&gbe=1&fl=0&b=0&fn=0&ti=1&d=0&ta=0&pv=0&c=0&m=0&t=0&ft=0&dn=upload.youtube.com&fe=scotty&ut=html_form';
my $upload_video_url2 = 'http://upload.youtube.com/upload/rupio';
my $upload_video_url3 = 'http://www.youtube.com/gen_204?a=multi_up_start&si=%SI%&uk=%UK%&ac=1&gbe=1&fl=0&b=0&fn=0&ti=1&d=0&ta=0&pv=0&c=0&m=0&t=0&ft=0&dn=upload.youtube.com&fe=scotty&ut=html_form';
my $upload_video_url4 = 'http://www.youtube.com/gen_204?a=multi_up_finish&si=%SI%&uk=%UK%&ac=1&gbe=1&fl=0&b=0&fn=0&ti=1&d=0&ta=0&pv=0&c=0&m=0&t=23001&ft=0&dn=upload.youtube.com&fe=scotty&ut=html_form';
my $upload_video_set_info = 'http://upload.youtube.com/my_videos_upload_json';


unless (@ARGV) {
    HELP_MESSAGE();
    exit 1;
}

my %opts;
getopts('l:p:f:c:t:d:x:', \%opts);

# if -l or -p are not given, try to use YT_LOGIN and YT_PASS constants
unless (defined $opts{l}) {
    unless (length YT_LOGIN) {
        preamble();
 print "Youtube username/login as neither defined nor passed as an argument\n";
        print "Use -l switch to specify the username\n";
        print "Example: -l joe_random\n";
        exit 1;
    }
    else {
        $opts{l} = YT_LOGIN;
    }
}

unless (defined $opts{p}) {
    unless (length YT_PASS) {
        preamble();
        print "Password was neither defined nor passed as an argument\n";
        print "Use -p switch to specify the password\n";
        print "Example: -p secretPass\n";
        exit 1;
    }
    else {
        $opts{p} = YT_PASS;
    }
}

unless (defined $opts{f} && length $opts{f}) {
    preamble();
    print "No video file was specified\n";
    print "Use -f switch to specify the video file\n";
    print 'Example: -f "C:\Program Files\movie.avi"', "\n";
    print 'Example: -f "/home/pkrumins/super.cool.video.wmv"', "\n";
    exit 1;
}

unless (-r $opts{f}) {
    preamble();
    print "Video file is not readable or does not exist\n";
    print "Check the permissions and the path to the file\n";
    exit 1;
}

unless (defined $opts{c} && length $opts{c}) {
    preamble();
    print "No video category was specified\n";
    print "Use -c switch to set the category of the video\n";
    print "Example: -c 20, would set category to Gadgets & Games\n\n";
    print_cats();
    exit 1;
}

unless (defined $cats{$opts{c}}) {
    preamble();
    print "Category '$opts{c}' does not exist\n\n";
    print_cats();
    exit 1;
}

unless (defined $opts{t} && length $opts{t}) {
    preamble();
    print "No video title was specified\n";
    print "Use -t switch to set the title of the video\n";
    print 'Example: -t "Super Cool Video Title"', "\n";
    exit 1;
}

unless (defined $opts{d} && length $opts{d}) {
    preamble();
    print "No video description was specified\n";
    print "Use -d switch to set the description of the video\n";
    print 'Example: -d "The coolest video description"', "\n";
    exit 1;
}

unless (defined $opts{x} && length $opts{x}) {
    preamble();
    print "No tags were specified\n";
    print "Use -x switch to set the tags\n";
    print 'Example: -x "foo, bar, baz, hacker, purl"', "\n";
    exit 1;
}

# tags should be at least two chars, can't be just numbers
my @tags = split /,\s+/, $opts{x};
my @filtered_tags = grep { length > 2 && !/^\d+$/ } @tags;
unless (@filtered_tags) {
    preamble();
    print "Tags must at least two chars in length and must not be numeric!\n";
    print "For example, 'foo', 'bar', 'yo29' are valid tags, but ";
    print "'22222', 'hi', 'b9' are invalid\n";
    exit 1;
} 

$opts{x} = join ', ', @filtered_tags;
# create the user agent, have it store cookies and
# pretend to be a cool windows firefox browser
my $ua = LWP::UserAgent->new(
    cookie_jar => {},
    agent => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) '.
             'Gecko/20070515 Firefox/2.0.0.4'
);

if (DEBUG) {
    $ua->add_handler("request_send",  sub { print "Request: \n"; shift->dump; print "\n"; return });
    $ua->add_handler("response_done", sub { print "Response: \n"; shift->dump; print "---\n"; return });
}

# let the user agent follow redirects after a POST request
push @{$ua->requests_redirectable}, 'POST';

print "Logging in to YouTube...\n";
login();

print "Uploading the video ($opts{t})...\n";
my $video_id = upload();

print "Done! http://www.youtube.com/watch?v=$video_id\n";

sub login {
    # go to login page to get redirected to google sign in page
    my $res = $ua->get($login_url);
    unless ($res->is_success) {
        die "Failed going to YouTube's login URL: ", $res->status_line;
    }

    # extract GALX id
    my $GALX = extract_field($res->content, qr/name="GALX".+?value="([^"]+)"/s);
    unless ($GALX) {
        die "Failed logging in. Unable to extract GALX identifier from Google's login page.";
    }

    # submit the login form
    $res = $ua->post($login_post_url,
        {
            ltmpl    => 'sso',
            continue => 'http://www.youtube.com/signin?action_handle_signin=true&nomobiletemp=1&hl=en_US&next=%2F',
            service  => 'youtube',
            uilel    => 3,
            hl       => 'en_US',
            GALX     => $GALX,
            Email    => $opts{l},
            Passwd   => $opts{p},
            rmShown  => 1,
            signIn   => 'Sign in',
            asts     => ''
        }
    );
    unless ($res->is_success) {
        die "Failed logging in: failed submitting login form: ", 
            $res->status_line;
    }

    # Get the meta http-equiv="refresh" url
    my $next_url = extract_field($res->content, qr/http-equiv="refresh" content="0; url=&#39;(.+?)&#39;/);
    unless ($next_url) {
        die "Failed logging in. Getting next url from http-equiv failed.";
    }
    $next_url = decode_entities($next_url);

    $res = $ua->get($next_url);
    unless ($res->is_success) {
        die "Failed logging in. Extraction of next_url failed: ",
            $res->status_line;
    }

    $res = $ua->get($login_cont_url);
    unless ($res->is_success) {
        die "Failed logging in. Navigation to YouTube.com failed: ", 
            $res->status_line;
    }

    # We have no good way to check if we really logged in.
    # I found that when you have logged in the upper right menu changes
    # and you have access to 'Sign Out' option.
    # We check for this string to see if we have logged in.
    unless ($res->content =~ /<form name="logoutForm"/) {
        die "Failed logging in: username/password incorrect";
    }
}

sub upload {
    # upload is actually a multistep process
    #
    
    # get upload page to extract some gibberish info
    my $resp = $ua->get($upload_url);
    unless ($resp->is_success) {
        die "Failed getting $upload_url: ", $resp->status_line;
    }

    my $SI = extract_field($resp->content, qr/"sessionKey": "([^"]+)"/);
    unless ($SI) {
        die "Failed extracting sessionKey. YouTube might have redesigned!";
    }

    my $UK = extract_field($resp->content, qr/"uploadKey": "([^"]+)"/);
    unless ($UK) {
        die "Failed extracting uploadKey. YouTube might have redesigned!";
    }

    my $session_token = extract_field($resp->content, qr/"session_token" value="([^"]+)"/);
    unless ($session_token) {
        die "Failed extracting session_token. YouTube might have redesigned!";
    }

    prepare_upload_urls($SI, $UK);

    # tell the server that we are up for uploads
    $resp = $ua->get($upload_video_url1);
    unless ($resp->is_success) {
        die "Failed getting upload_video_url1: ", $resp->status_line;
    }

    # now lets post some more gibberish data
my $post_data_gibberish =<<EOL;
{"protocolVersion":"0.7","createSessionRequest":{"fields":[{"external":{"name":"file","filename":"$opts{f}","formPost":{}}},{"inlined":{"name":"return_address","content":"upload.youtube.com","contentType":"text/plain"}},{"inlined":{"name":"upload_key","content":"$UK","contentType":"text/plain"}},{"inlined":{"name":"action_postvideo","content":"1","contentType":"text/plain"}},{"inlined":{"name":"live_thumbnail_id","content":"$SI.0","contentType":"text/plain"}},{"inlined":{"name":"parent_video_id","content":"","contentType":"text/plain"}},{"inlined":{"name":"allow_offweb","content":"True","contentType":"text/plain"}},{"inlined":{"name":"uploader_type","content":"Web_HTML","contentType":"text/plain"}}]},"clientId":"scotty html form"}
EOL

    $resp = $ua->post($upload_video_url2, Content => $post_data_gibberish);
    unless ($resp->is_success) {
        die "Failed posting gibberish to upload_video_url2: ", $resp->status_line
    }

    # extract the file upload url
    my $file_upload_url = extract_field($resp->content, qr/"url":"([^"]+)"/);
    unless ($file_upload_url) {
        die "Failed extracting file upload url. YouTube might have redesigned!";
    }

    # now lets tell the server that we are starting to upload
    $resp = $ua->get($upload_video_url3);
    unless ($resp->is_success) {
        die "Failed getting upload_video_url3: ", $resp->status_line;
    }

    # now lets post the video
    my $starttime = time();
    my $size = -s $opts{f};
    print "\n";
    my $req = POST($file_upload_url, 
        {
            Filedata => [ $opts{f} ]
        },
        "Content_Type" => "form-data"
    );
    
    
    # wrap content generator sub
    my $gen = $req->content;
    die unless ref($gen) eq "CODE";
    my $total = 0;
    
    $req->content(sub {
    my $chunk = &$gen();
    $total += length($chunk);
    print "\r$total / $size bytes (".int($total/$size*100)."%) sent, ".int($total/1000/(time()-$starttime+1)) . " k / sec ";
    return $chunk;
    });
    
    $resp = $ua->request($req);
    print "\n";

    unless ($resp->is_success) {
        die "Failed uploading the file: ", $resp->status_line;
    }

    my $video_id = extract_field($resp->content, qr/"video_id":"([^"]+)"/);

    # tell the server that we are done
    $resp = $ua->get($upload_video_url4);
    unless ($resp->is_success) {
        die "Failed getting upload_video_url4: ", $resp->status_line;
    }

    # finally set the video info
    $resp = $ua->post($upload_video_set_info,
        {
            session_token     => $session_token,
            action_edit_video => 1,
            updated_flag      => 0,
            video_id          => $video_id,
            title             => $opts{t},
            description       => $opts{d},
            keywords          => $opts{x},
            category          => $opts{c},
            privacy           => 'public'
        }
    );

    unless ($resp->is_success) {
        die "Failed setting video info (but it uploaded ok!): ", $resp->status_line;
    }

    if ($resp->content =~ /"errors":\s*\[(.+?)\]/) {
        die "The video uploaded OK, but there were errors setting the video info:\n", $1;
    }

    return $video_id;
}

sub prepare_upload_urls {
    my ($SI, $UK) = @_;
    for ($upload_video_url1, $upload_video_url3, $upload_video_url4)
    {
        s/%SI%/$SI/;
        s/%UK%/$UK/;
    }
}

sub extract_field {
    my ($content, $rx) = @_;
    if ($content =~ /$rx/) {
        return $1
    }
}

sub HELP_MESSAGE {
    preamble();
    print "Usage: $0 ",
          "-l [login] ", 
          "-p [password] ",
          "-f <video file> ",
          "-c <category> ",
          "-t <title> ",
          "-d <description> ",
          "-x <comma, separated, tags>\n\n";
    print_cats();
}

sub print_cats {
    print "Possible categories (for -c switch):\n";
    printf "%-4s - %s\n", $_, $cats{$_} foreach (sort {
        $cats{$a} cmp $cats{$b}
    } keys %cats);
}

sub VERSION_MESSAGE {
    preamble();
    print "Version: v", VERSION, "\n";
}

sub preamble {
    print "YouTube video uploader by Peteris Krumins (peter\@catonmat.net)\n";
    print "http://www.catonmat.net  --  good coders code, great reuse\n";
    print "\n"
}


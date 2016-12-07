
# Frotz

Play Infocom games in Slack.

## Requirements

emerge/yum/apt the *frotz* package.

# Configuration

## lighttpd

A fastcgi server and environment variables.

```
server.modules += ("mod_fastcgi")

fastcgi.server = (

    "/frotz" =>
        ( "ruby" =>
            (
            "socket"    =>    "/var/run/lighttpd/lighttpd-fastcgi-frotz-" + PID + ".socket",
            "bin-path"  =>    "/var/www/localhost/htdocs/frotz/frotz.rb",
            "max-procs" =>    "1"
        )
    )
)

$HTTP["url"] =~ "^/frotz" {
    setenv.add-environment = (
        "HOME" => "/var/www/localhost/htdocs",
        "TERM" => "vt100",
        "SLACK_TOKEN" => "<token>"
    )
}

```

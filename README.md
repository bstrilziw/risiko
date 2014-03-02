Risiko
======

Unser Risiko-Klon läuft mit dem Ruby-Gem `sinatra` im Browser. Damit das Spiel lokal läuft, müssen die folgenden Gems installiert werden:

    sinatra
    sinatra-contrib
    slim
    json
    digest
    pony
    dm-sqlite-adapter
    data_mapper

Außerdem muss SQLite3 installiert sein: http://www.sqlite.org/download.html

Sind alle Gems installiert, wechselt man mit der Konsole in das risiko-Verzeichnis und startet es mit `ruby main.rb` und ruft es über http://localhost:4567 im Browser auf. 

Möchte man mit mehreren Spielern im gleichen Netzwerk spielen, muss man die IP-Adresse herausfinden, auf die sich dann die anderen Clients verbinden können. Wäre die IP-Adresse `46.59.134.95`, so würde man über http://46.59.134.95:4567 auf das Spiel zugreifen können. 

Vorhandene Benutzernamen sind: 

    admin
    benjamin
    bjoern
    hendrik
    timo
    tobias
    user

Sie unterscheiden sich nicht von den Rechten, nur von den Anzeigenamen im Spiel. 
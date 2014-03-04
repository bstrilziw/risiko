Risiko
======

Unser Risiko-Klon läuft mit dem Ruby-Gem `sinatra` im Browser. Damit das Spiel lokal läuft, müssen die folgenden Gems installiert werden: (Gems werden über den Befehl: gem install *zugehöriger Name* installiert)

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

Möchte man mit mehreren Spielern im gleichen Netzwerk spielen, muss man die IP-Adresse herausfinden, auf die sich dann die anderen Clients verbinden können. Wäre die IP-Adresse `46.59.134.95` des Server-Hosts, so würde man über http://46.59.134.95 auf das Spiel zugreifen können. Wichtig hierbei ist, dass der Host den Port:80 freigibt. Dieser Port kann manuell in der main.rb angepasst werden. 

Vorhandene Benutzernamen sind: 

	admin
	benjamin
	hendrik
	timo
	tobias
	user

Das Passwort bei der Anmeldung einfach leer lassen. Sie unterscheiden sich nicht von den Rechten, nur von den Anzeigenamen im Spiel.

Ein neuer Account kann jederzeit erstellt werden. Es werden auch automatisch generierte Emails zur Accountbestätigung versendet, bisher aber nur an ein Test-Postfach.

Steuerung

Wenn man eingeloggt ist, bieten sich einem die folgenden Möglichkeiten:

	Spiel suchen 
	Spiel erstellen

Ein Spiel hat immer einen "Host" - einen der das Spiel/Lobby erstellt/geöffnet hat und in der Lage ist, das Spiel zu starten.

In der linken oberen Ecke ist die Phasenanzeige. Sie zeigt ob man am Zug ist, und in welcher Phase seines Zuges man sich befindet.
	Phase 1: Einheiten setzen
		Die Einheiten die man zum Beginn einer Runde erhält werden auf den eigenen Ländern per Rechtsklick 			gesetzt.
	Phase 2: Angreifen
		Man wählt eines seiner Länder aus (dieses muss mehr als 1 Einheit besitzen), wählt aus, wieviele 			Einheiten in den Kampf geschickt werden sollen und wählt darauf das anzugreifende Land aus.
	Phase 3: Einheiten verteilen
		Man kann seine Einheiten an verbundenen Ländern verteilen, jedes Land muss aber immer 1 Einheit 			besitzen.
		
Ziel ist bisher die absolute Weltherrschaft, es gibt noch keine Unterziele oder Missionen.

Die Datenbank wird bei jedem Serverneustart geleert; lediglich Testdatensätze (s.o.) bleiben erhalten.

![Risiko Klon](https://raw.github.com/bstrilziw/risiko/master/assets/images/screenshots/screen2.png)

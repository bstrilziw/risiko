var headerMenu;
var phase = 0;
var placeableUnits = 0;
var playerNumber;
var selectedLand1 = null, selectedLand2 = null;
var unitCount = new Object(), owner = new Object();
var hasClickedOnRules = false;
var site;
var updateCounter = 0;
// Spielerinformationen
var playerName = new Object();
var playerColor = new Object();

$(document).ready(function() {
	headerMenu = $('#menu');

	$('#toggleFullscreen').click(function() {
		if (!$(this).hasClass('open')) {
			$(document).fullScreen(true);
			$(this).addClass('open');
		} else {
			$(document).fullScreen(false);
		}
	});

	$(document).bind("fullscreenchange", function() {
		if (!$(document).fullScreen()) {
			$('#toggleFullscreen').removeClass('open');
		}
	});

	// Seite erkennen
	site = $('#site_identifier').html();
	if (typeof site === "undefined")
		site = "unknown";
	else
		site = site.trim();

	$('.land').mouseenter(function() {
		// Land hervorheben
		$(this).appendTo($('#images'));
		// Glüheffekt von allen Ländern entfernen
		$('.land_selected').attr('class', 'land');
		// und für das gewählte hinzufügen
		$(this).attr("class", "land land_selected");
	});

	$('#background').click(function() {
		selectedLand1 = null;
		selectedLand2 = null;
		destroyUnitPicker();
		updateHighlight();
	});

	$('.land').click(function() {
		// Verteilungsphase
		if (phase === 0 && placeableUnits > 0) {
			if (owner[name(this)] !== playerNumber) {
				return;
			}
			// Einheiten verteilen
			$.ajax({
				type: "POST",
				url: "/game/place_unit",
				data: {land_name: name(this)}
			});
			placeableUnits--;
			// Beschriftung updaten
			var text_element = $('#text_' + name(this)).children().last();
			text_element.text(parseInt(text_element.text()) + 1);
			if (placeableUnits === 0) {
				phase = 3;
			}
			updateCounter++;
			updatePhaseText();
		}
		// Angriffsphase
		else if (phase === 1) {
			if (selectedLand1 === null) {
				if (owner[name(this)] !== playerNumber) {
					return;
				}
				selectedLand1 = this;

				showUnitPicker(selectedLand1.id);
			}
			// eigenes Land?
			else if (owner[name(this)] === playerNumber) {
				selectedLand1 = this;
				showUnitPicker(selectedLand1.id);
				selectedLand2 = null;
			}
			// feindliches Land?
			else {
				// kein Nachbarland von selectedLand1?
				if (neighbors[name(selectedLand1)].indexOf(name(this)) < 0) {
					selectedLand1 = null;
					selectedLand2 = null;
					destroyUnitPicker();
				}
				else {
					selectedLand2 = this;
					updateHighlight();
					// ANGRIFF hier durchführen
					// Anzahl der angreifenden Einheiten auswählen
					$.ajax({
						type: "POST",
						url: "/game/attack",
						data: {source: name(selectedLand1), target: name(selectedLand2), units: $('#unitpicker input').val().toString()}
					});
					updateCounter++;
					destroyUnitPicker();
					selectedLand1 = null;
					selectedLand2 = null;
					update();
				}
			}
			updateHighlight();
		}
		// Verschiebungsphase
		else if (phase === 2) {
			if (owner[name(this)] !== playerNumber) {
				destroyUnitPicker();
				selectedLand1 = null;
				selectedLand2 = null;
			}
			else if (selectedLand1 === null || !connectedToLand1[name(this)]) {
				selectedLand1 = this;
				calculateConnections();
				showUnitPicker(this.id);
				selectedLand2 = null;
			}
			else if (connectedToLand1[name(this)]) {
				selectedLand2 = this;
				updateHighlight();
				$.ajax({
					type: "POST",
					url: "/game/transfer",
					data: {source: name(selectedLand1), target: name(selectedLand2), units: $('#unitpicker input').val().toString()}
				});
				updateCounter++;
				destroyUnitPicker();
				selectedLand1 = null;
				selectedLand2 = null;
				update();
			}
			updateHighlight();
		}
	});

	if (site === "lobby") {
		$('#button_add_ai').click(function() {
			$(this).attr("disabled", true).addClass("loading");
			$.ajax({
				type: "POST",
				url: "/game/add_ai"
			}).fail(function() {
				// maximale Spielerzahl erreicht
			});
		});
		$('#button_remove_ai').click(function() {
			$(this).attr("disabled", true).addClass("loading");
			$.ajax({
				type: "POST",
				url: "/game/remove_ai"
			});
		});
	}
	$('#button_next_phase').click(function() {
		if (phase === 3)
			return;
		phase = 3; //warten
		updateCounter++;

		updatePhaseText();
		$.ajax({
			type: "POST",
			url: "/game/next_phase"
		});
		updateHighlight();
	});

	// Spielerdaten ermitteln
	$('#playerlist ul li').each(function() {
		playerName[Number($(this).children().first().text())] =
				$(this).children().eq(1).text().trim();
		playerColor[Number($(this).children().first().text())] =
				$(this).children().last().css("background-color");
	});

	// öffnet das Menü
	headerMenu.find('span').bind('click', function() {
		$(this).parent().toggleClass('open');
		return false;
	});

	//Regeln
	$("#regeln").click(function() {
		$(".regeln").toggle('clip', 'fast');
		hasClickedOnRules = true;
	});

	$("#exit").click(function() {
		$(".regeln").toggle('clip', 'fast');
	});

	$(".regeln").toggle();

	$(".regeln2, .phase2").accordion({
		collapsible: true,
		heightStyle: "content"
	});

	$('.regeln').click(function() {
		hasClickedOnRules = true;
	});

	// schließt das Menü, falls man irgendwo hinklickt
	$('body').bind('click', function() {
		if (headerMenu.hasClass('open')) {
			headerMenu.removeClass('open');
		}
		if (!hasClickedOnRules && $('.regeln').css('display') === "block")
			$(".regeln").toggle('clip', 'fast');
		hasClickedOnRules = false;
	});

	// Chat-Toggle
	$(".button#toggle").click(function() {
		$(".chatbox").slideToggle(200);
		$("#posts").animate({scrollTop: 10000}, 'fast');
	});
	$(".chatbox").toggle();

	$(".fancybox").fancybox();

	timer();
});

// Timer für Update
function timer() {
	if (site === "game") {
		update();
		updateChat();
	} else if (site === "lobby") {
		updateLobby();
	} else if (site === "list") {
		updateList();
	}
	setTimeout(function() {
		timer();
	}, 3000);
}

function updateList() {
	$.ajax({
		type: "GET",
		url: "/updateGameList",
		success: function(data) {
			data = JSON.parse(data);
			$("#gamelist").empty();
			if (data.length === 0) {
				$("#gamelist").append("<h3>Derzeit gibt es keine Spiele.</h3>")
			}
			for (var i = 0; i < data.length; i++) {
				$("#gamelist").append('<li><a href="/game/join/' + data[i].name + '">'
						+ (i + 1) + ". " + data[i].name + " [Ersteller: " + data[i].creator +
						"] [Spieler: " + data[i].playerCount + "/" + data[i].maxPlayerCount + "]</a></li>");
			}
		}
	});
}

function updateLobby() {
	$.ajax({
		type: "GET",
		url: "/updatePlayerList",
		success: function(data) {
			data = JSON.parse(data);
			if (data.game_started)
				location.reload();
			$("#lobbylist").empty();
			for (var i = 0; i < data.players.length; i++) {
				$("#lobbylist").append("<li>" + data.players[i] + "</li>");
			}
			$('#button_add_ai, #button_remove_ai').attr("disabled", false).removeClass("loading");
		}
	});
}

function updateChat() {
	$.ajax({
		type: "GET",
		url: "/updateChat",
		success: function(data) {
			data = JSON.parse(data);
			$("#posts").empty();
			for (var i = 0; i < data.length; i++) {
				$("#posts").append("<li>" + data[i] + "</li>");
			}
			$("#posts").animate({scrollTop: $(document).height()}, "slow");
		}
	});
}

function update() {
	$.ajax({
		type: "GET",
		url: "/update",
		data: {updateCount: updateCounter},
		success: function(data) {
			// Daten verarbeiten
			data = JSON.parse(data);
			if (data.updateCount < updateCounter)
				return;
			// Laender aktualisieren
			for (var i = 0; i < data.mapdata.length; i++) {
				var land = data.mapdata[i];
				$('#text_' + land.name).children().last().text(land.unit_count);
				owner[land.name] = land.owner;
				unitCount[land.name] = land.unit_count;
			}
			// Spielende abfangen
			if (data.gameOver) {
				$('#active_player').text("Gewinner: " + playerName[data.active_player]);
				$('#phase').text("Das Spiel ist vorbei.");
				$('#button_next_phase').attr("disabled", "disabled");
				phase = 3;
				updateHighlight();
				return;
			}
			placeableUnits = data.placeable_units;
			// Phase aktualisieren
			phase = data.phase;
			updatePhaseText();
			// Aktiver-Spieler-Beschriftung anpassen
			$('#active_player').text("Aktiver Spieler: " + playerName[data.active_player]);
			// Spieler Namen aktualisieren
			if (phase !== 3) {
				playerNumber = data.active_player;
			}
			updateHighlight();
		}
	});
}

function updatePhaseText() {
	switch (phase) {
		case 0:
			$('#phase').text("Verteilen Sie ihre Einheiten. (" + placeableUnits + ")");
			$('#button_next_phase').removeAttr("disabled");
			break;
		case 1:
			$('#phase').text("Angriff durchfuehren.");
			$('#button_next_phase').removeAttr("disabled");
			break;
		case 2:
			$('#phase').text("Einheiten verschieben.");
			$('#button_next_phase').removeAttr("disabled");
			break;
		case 3:
			$('#phase').text("Warten...");
			$('#button_next_phase').attr("disabled", "disabled");
			break;
	}
}

function send(textbox) {
	$.ajax({
		type: "POST",
		url: "/chat",
		data: {message: textbox.value}
	});
	textbox.value = "";
	textbox.focus();
	updateChat();
	return false;
}

function name(object) {
	return $(object).attr('id').slice(5);
}

var neighbors = {
	// Nord-Amerika
	"alaska": ["alberta", "nordwest-territorium", "kamtschatka"],
	"alberta": ["alaska", "nordwest-territorium", "weststaaten", "ontario"],
	"weststaaten": ["alberta", "mittel-amerika", "ontario", "oststaaten"],
	"mittel-amerika": ["weststaaten", "oststaaten", "venezuela"],
	"nordwest-territorium": ["alaska", "alberta", "groenland", "ontario"],
	"ontario": ["nordwest-territorium", "alberta", "weststaaten",
		"oststaaten", "quebec", "groenland"],
	"oststaaten": ["weststaaten", "mittel-amerika", "ontario", "quebec"],
	"quebec": ["ontario", "oststaaten", "groenland"],
	"groenland": ["nordwest-territorium", "ontario", "quebec", "island"],
	// Süd-Amerika
	"venezuela": ["mittel-amerika", "peru", "brasilien"],
	"peru": ["venezuela", "brasilien", "argentinien"],
	"brasilien": ["venezuela", "peru", "argentinien", "nordwest-afrika"],
	"argentinien": ["peru", "brasilien"],
	// Afrika
	"nordwest-afrika": ["brasilien", "aegypten", "ost-afrika", "kongo", "west-europa", "sued-europa"],
	"aegypten": ["nordwest-afrika", "ost-afrika", "mittlerer-osten", "sued-europa"],
	"ost-afrika": ["nordwest-afrika", "aegypten", "kongo", "sued-afrika", "mittlerer-osten", "madagaskar"],
	"kongo": ["nordwest-afrika", "ost-afrika", "sued-afrika"],
	"sued-afrika": ["ost-afrika", "kongo", "madagaskar"],
	"madagaskar": ["ost-afrika", "sued-afrika"],
	// Europa
	"island": ["groenland", "skandinavien", "gross-britannien"],
	"skandinavien": ["island", "ukraine", "gross-britannien", "mittel-europa"],
	"ukraine": ["skandinavien", "mittel-europa", "mittlerer-osten", "afghanistan", "ural", "sued-europa"],
	"gross-britannien": ["island", "skandinavien", "mittel-europa", "west-europa"],
	"mittel-europa": ["skandinavien", "ukraine", "gross-britannien", "west-europa", "sued-europa"],
	"west-europa": ["nordwest-afrika", "gross-britannien", "mittel-europa", "sued-europa"],
	"sued-europa": ["nordwest-afrika", "aegypten", "ukraine", "mittel-europa", "west-europa", "mittlerer-osten"],
	// Asien
	"mittlerer-osten": ["aegypten", "ost-afrika", "ukraine", "afghanistan", "indien", "sued-europa"],
	"afghanistan": ["ukraine", "mittlerer-osten", "ural", "china", "indien"],
	"ural": ["ukraine", "afghanistan", "sibirien", "china"],
	"sibirien": ["ural", "jakutien", "irkutsk", "mongolei", "china"],
	"jakutien": ["sibirien", "irkutsk", "kamtschatka"],
	"kamtschatka": ["alaska", "jakutien", "irkutsk", "mongolei", "japan"],
	"irkutsk": ["sibirien", "jakutien", "mongolei", "kamtschatka"],
	"mongolei": ["sibirien", "irkutsk", "japan", "china", "kamtschatka"],
	"japan": ["mongolei", "china", "kamtschatka"],
	"china": ["afghanistan", "ural", "sibirien", "mongolei", "japan", "indien", "siam"],
	"indien": ["mittlerer-osten", "afghanistan", "china", "siam"],
	"siam": ["china", "indien", "indonesien"],
	// Ozeanien
	"indonesien": ["siam", "neu-guinea", "west-australien"],
	"neu-guinea": ["indonesien", "ost-australien"],
	"ost-australien": ["neu-guinea", "west-australien"],
	"west-australien": ["indonesien", "ost-australien"]
};

function updateHighlight() {
	if (phase === 0) {
		$('.land').each(function() {
			$(this).css('fill', playerColor[owner[name(this)]]);
		});
	}
	else if (phase === 1) {
		$('.land').each(function() {
			if (selectedLand1 === null || selectedLand1 === this
					|| selectedLand2 === this || selectedLand2 === null
					&& neighbors[name(selectedLand1)].indexOf(name(this)) >= 0
					&& owner[name(this)] !== playerNumber) {
				$(this).css('fill', playerColor[owner[name(this)]]);
			}
			else {
				$(this).css('fill', '#888');
			}
		});
	}
	else if (phase === 2) {
		$('.land').each(function() {
			if (selectedLand1 === null || (selectedLand2 === null && connectedToLand1[name(this)]) || selectedLand1 === this || selectedLand2 === this) {
				$(this).css('fill', playerColor[owner[name(this)]]);
			} else {
				$(this).css('fill', '#888');
			}
		});
	}
	else if (phase === 3) {
		$('.land').each(function() {
			$(this).css('fill', playerColor[owner[name(this)]]);
		});
	}
}

function showUnitPicker(element) {
	destroyUnitPicker();
	var path = $('#' + element);
	var path_bbox = path[0].getBBox();
	var worldmap_margin_top = $('.content .top').height();

	var selected_land = element.split('_')[1];
	var max = $('#text_' + selected_land).children().last().text() - 1;

	$('.content').append('<div id="unitpicker" style="top: ' + (path_bbox.y + path_bbox.height + worldmap_margin_top) + 'px; left: ' + (path_bbox.x + (path_bbox.width / 2) - 30) + 'px"><input value="1" /></div>');
	$('#unitpicker input').spinner({min: 1, max: max}).focus();
	$('#unitpicker input').val(max);
}

function destroyUnitPicker() {
	$('#unitpicker input').spinner("destroy").parent().remove();
}

var connectedToLand1 = new Object();

function calculateConnections() {
	// Alle Länder des Spielers ermitteln
	for (var landName in owner) {
		if (owner[landName] === playerNumber) {
			if (landName === name(selectedLand1)) {
				connectedToLand1[landName] = true;
			} else {
				connectedToLand1[landName] = false;
			}
		}
	}
	// Solange iterieren, bis sich nichts mehr veraendert
	var change = true;
	while (change) {
		change = false;
		for (var landName in connectedToLand1) {
			if (connectedToLand1[landName] === true) {
				for (var i in neighbors[landName]) {
					if (owner[neighbors[landName][i]] === playerNumber && !connectedToLand1[neighbors[landName][i]]) {
						change = true;
						connectedToLand1[neighbors[landName][i]] = true;
					}
				}
			}
		}
	}
}
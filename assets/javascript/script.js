var headerMenu;
var phase = 0;
var placeableUnits = 0;
var playerName;
var selectedLand1 = null, selectedLand2 = null;
var unitCount = new Object(), owner = new Object();

$(document).ready(function() {
	headerMenu = $('#menu');

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
		updateHighlight();
	});

	$('.land').click(function() {
		// Verteilungsphase
		if (phase === 0 && placeableUnits > 0) {
			if (owner[name(this)] !== playerName) {
				return;
			}
			// Einheiten verteilen
			$.ajax({
				type: "POST",
				url: "/update/new_unit",
				data: {data: JSON.stringify(new Array(
							{land_name: name(this),
								unit_count: 1}
					))}
			});
			placeableUnits--;
			// Beschriftung updaten
			var text_element = $('#text_' + name(this)).children().last();
			text_element.text(parseInt(text_element.text()) + 1);
			// automatisch in die nächste Phase wechseln, sobald alle Einheiten aufgebraucht sind
			if (placeableUnits === 0) {
				phase++;
				$.ajax({
					type: "POST",
					url: "/update/phase"
				});
			}
			updatePhaseText();
		}
		// Angriffsphase
		else if (phase === 1) {
			if (selectedLand1 === null) {
				if (owner[name(this)] !== playerName) {
					return;
				}
				selectedLand1 = this;
			}
			// eigenes Land?
			else if (owner[name(this)] === playerName) {
				selectedLand1 = this;
				selectedLand2 = null;
			}
			// feindliches Land?
			else {
				// kein Nachbarland von selectedLand1?
				if (neighbors[name(selectedLand1)].indexOf(name(this)) < 0) {
					selectedLand1 = null;
					selectedLand2 = null;
				}
				else {
					selectedLand2 = this;
					// ANGRIFF hier durchführen
					// Anzahl der angreifenden Einheiten auswählen
				}
			}
			updateHighlight();
		}
		// Verschiebungsphase
		else if (phase === 2) {
			if (owner[name(this)] !== playerName) {
				return;
			}
		}
	});

	$('#button_next_phase').click(function() {
		if (phase === 3) // Button sollte disabled / ausgeblendet werden
			return;
		if (++phase === 4) {
			phase = 0;
		}
		updatePhaseText();
		$.ajax({
			type: "POST",
			url: "/update/phase"
		});
		updateHighlight();
	});

	// öffnet das Menü
	headerMenu.find('span').bind('click', function() {
		$(this).parent().toggleClass('open');
		return false;
	});

	// schließt das Menü, falls man irgendwo hinklickt
	$('body').bind('click', function() {
		if (headerMenu.hasClass('open')) {
			headerMenu.removeClass('open');
		}
	});

	// Update request alle 5 Sekunden
	update();

	// Chat-Toggle
	$(".button#toggle").click(function() {
		$(".chatbox").slideToggle(200);
		$("#posts").animate({scrollTop: 10000}, 'fast');
	});
	$(".chatbox").toggle();
	timer();

});

// Timer für Chat-Update
function timer() {
	updateChat();
	setTimeout(function() {
		timer();
	}, 5000);
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
		}
	});
}

function update() {
	$.ajax({
		type: "GET",
		url: "/update",
		success: function(data) {
			// Daten verarbeiten
			data = JSON.parse(data);
			// Laender aktualisieren
			for (var i = 0; i < data.mapdata.length; i++) {
				var land = data.mapdata[i];
				$('#text_' + land.name).children().last().text(land.unit_count);
				owner[land.name] = land.owner;
				unitCount[land.name] = land.unit_count;
			}
			placeableUnits = data.placeable_units;
			// Phase aktualisieren
			phase = data.phase;
			updatePhaseText();
			// Aktiver-Spieler-Beschriftung anpassen
			$('#active_player').find('#player_name').text(data.active_player).parent().removeClass().addClass("player"+data.active_player_id);
			// Spieler Namen aktualisieren
			if (phase !== 3) {
				playerName = data.active_player;
			}
			updateHighlight();
		}
	});
	setTimeout(function() {
		update();
	}, 5000);
}

function updatePhaseText() {
	switch (phase) {
		case 0:
			$('#phase').text("Verteilen Sie Ihre Einheiten. (" + placeableUnits + ")");
			break;
		case 1:
			$('#phase').text("Angriff durchfuehren.");
			break;
		case 2:
			$('#phase').text("Einheiten verschieben.");
			break;
		case 3:
			$('#phase').text("Warten...");
			break;
	}
}

function getColorToName(name) {
	var color = "#888";
	$('#playerlist ul li').each(function() {
		if ($(this).find('span.name').text() === name) {
			color = $(this).find('span.color').css('background-color');
		}
	});
	return color;
}

function intToColor(int) {
	switch (int) {
		case 0:
			return '#ff0000';
		case 1:
			return '#00ff00';
		case 2:
			return '#0000ff';
		case 3:
			return '#dddd00';
		case 4:
			return '#00dddd';
		case 5:
			return '#dd00dd';
		case 6:
			return '#ff8800';
		case 7:
			return '#00ff88';
		case 8:
			return '#8800ff';
		case 9:
			return '#88ff00';
		default:
			return 'grey';
	}
}

function randColor(currentColor) {
	var newColor = currentColor;
	while (newColor === currentColor) {
		newColor = intToColor(Math.floor((Math.random() * 10)));
	}
	return newColor;
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
	"nordwest-territorium": ["alaska", "alberta", "groenland"],
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
	"indonesien": ["siam", "neu-guinea", "ost-australien", "west-australien"],
	"neu-guinea": ["indonesien", "ost-australien"],
	"ost-australien": ["indonesien", "neu-guinea", "west-australien"],
	"west-australien": ["indonesien", "ost-australien"]
};

function updateHighlight() {
	if (phase === 0) {
		$('.land').each(function() {
			$(this).css('fill', getColorToName(owner[name(this)]));
		});
	}
	else if (phase === 1) {
		$('.land').each(function() {
			if (selectedLand1 === null || selectedLand1 === this
					|| selectedLand2 === this || selectedLand2 === null
					&& neighbors[name(selectedLand1)].indexOf(name(this)) >= 0
					&& owner[name(this)] !== playerName) {
				$(this).css('fill', getColorToName(owner[name(this)]));
			}
			else {
				$(this).css('fill', '#888');
			}
		});
	}
	else if (phase === 2) {
		$('.land').each(function() {
			$(this).css('fill', getColorToName(owner[name(this)]));
		});
	}
}
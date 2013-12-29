var headerMenu;
var phase = 0;
var placeable_units = 0;
var laender;

$(document).ready( function() {
    headerMenu = $('#menu');
	
	$('.land').mouseenter( function() {
		// Land hervorheben
        $(this).appendTo($('#images'));
		// Glüheffekt von allen Ländern entfernen
        $('.land_selected').attr('class', 'land');
        // und für das gewählte hinzufügen
        $(this).attr("class", "land land_selected");
	});
	
	// Farbwechsel der Länder
    $('.land').click( function() {
        
        // Flächenfarbe des Landes zufällig setzen
        $(this).css('fill', randColor());
		
		if (phase === 0 && placeable_units > 0) {
			// Einheiten verteilen
			$.ajax({
				type: "POST",
				url: "/update/new_unit",
				data: {data: JSON.stringify( new Array(
							{land_name: $(this).attr('id').slice(5, $(this).attr('id').length),
								unit_count: 1}
						) ) }
			});
			placeable_units--;
			// Beschriftung updaten
			var text_element = $('#text_' + $(this).attr('id').slice(5, $(this).attr('id').length) ).children().last();
			text_element.text(parseInt(text_element.text()) + 1);
			// automatisch in die nächste Phase wechseln, sobald alle Einheiten aufgebraucht sind
			if (placeable_units === 0) {
				phase++;
				updatePhaseText();
				$.ajax({
					type: "POST",
					url: "/update/phase"
				});
			}
		}
    });
	
	$('#button_next_phase').click( function() {
		if (phase === 3) // Button sollte disabled werden
			return;
		if (++phase === 4) {
			phase = 0;
		}
		updatePhaseText();
		$.ajax({
			type: "POST",
			url: "/update/phase"
		});
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
		$("#posts").animate({ scrollTop: 10000 }, 'fast');
    });
	$(".chatbox").toggle();
	timer();

});

// Timer für Chat-Update
function timer() {
	updateChat();
	setTimeout(function(){
		timer();
	}, 5000);
}
function updateChat() {
	$.ajax({
		type: "GET",
		url: "/updateChat",
		success: function(data){
			data = JSON.parse(data);
			$("#posts").empty();
			for (var i = 0; i < data.length; i++){
				$("#posts").append("<li>" + data[i] + "</li>");
			}
		}
	});
};
function update() {
	$.ajax({
		type: "GET",
		url: "/update",
		success: function(data) {
			// Daten verarbeiten
			data = JSON.parse(data);
			// Laender aktualisieren
			laender = data.mapdata;
			for (var i = 0; i < laender.length; i++) {
				var land = laender[i];
				$('#text_' + land.name).children().last().text(land.unit_count);
				$('#land_' + land.name).css('fill', getColorToName(land.owner));
			}
			// Phase aktualisieren
			phase = data.phase;
			updatePhaseText();
			// Aktiver-Spieler-Beschriftung anpassen
			$('#active_player').text("Aktiver Spieler: " + data.active_player);
			placeable_units = data.placeable_units;
		}
	});
	setTimeout( function() {
		update();
	}, 5000);
}

function updatePhaseText() {
	switch(phase) {
		case 0: $('#phase').text("Verteilen Sie ihre Einheiten.");
		break;
		case 1: $('#phase').text("Angriff durchfuehren.");
		break;
		case 2: $('#phase').text("Einheiten verschieben.");
		break;
		case 3: $('#phase').text("Warten...");
		break;
	}
}

function getColorToName(name) {
	var color = "#888";
	$('#playerlist ul li').each( function() {
		if ( $(this).children().first().text() === name ) {
			color = $(this).children().last().text().trim();
		}
	});
	return color;
}

function intToColor(int) {
     switch(int) {
        case 0: return '#ff0000';
        case 1: return '#00ff00';
        case 2: return '#0000ff';
        case 3: return '#dddd00';
        case 4: return '#00dddd';
        case 5: return '#dd00dd';
        case 6: return '#ff8800';
        case 7: return '#00ff88';
        case 8: return '#8800ff';
        case 9: return '#88ff00';
        default: return 'grey';
    }
}

function randColor(currentColor) {
    var newColor = currentColor;
    while (newColor === currentColor) {
        newColor = intToColor( Math.floor((Math.random()*10)) );
    }
    return newColor;
}

function send(textbox) {
	$.ajax({
		type: "POST",
		url: "/chat",
		data:{message: textbox.value}
	});	
	textbox.value = "";
	textbox.focus();
	updateChat();
	return false;
};
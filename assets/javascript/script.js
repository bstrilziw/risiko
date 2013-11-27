var headerMenu;

$(document).ready( function() {
	headerMenu = $('#menu');
	
    $('.land').click( function() {
        // Land hervorheben
        $(this).appendTo($('#worldmap'));
        // Glüheffekt von allen Ländern entfernen
        $('.land').css('filter', 'none');
        // und für das gewählte hinzufügen
        $(this).css('filter', 'url(#filter_glow)');
        // Flächenfarbe des Landes zufällig setzen
        $(this).css('fill', randColor());
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
});

function intToColor(int) {
     switch(int) {
        case 0: return 'yellow';
        case 1: return 'red';
        case 2: return 'green;';
        case 3: return '#8866ff';
        case 4: return 'purple';
        case 5: return 'blue';
        case 6: return 'black';
        case 7: return 'orange';
        case 8: return 'lime';
        case 9: return '#44ff77';
        default: return 'grey';
    }
}
function randColor(currentColor) {
    var newColor = currentColor;
    while (newColor === currentColor) {
        newColor = intToColor( Math.floor((Math.random()*10)+1) );
    }
    return newColor;
}
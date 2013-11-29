var headerMenu;

$(document).ready( function() {
    headerMenu = $('#menu');
        
    $('.land').click( function() {
        // Land hervorheben
        $(this).appendTo($('#images'));
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
        newColor = intToColor( Math.floor((Math.random()*10)+1) );
    }
    return newColor;
}
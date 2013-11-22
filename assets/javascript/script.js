$(document).ready( function() {
    $('.land').click( function() {
        $(this).css('fill', randColor());
    });
});

function intToColor(int) {
     switch(int) {
        case 0: return 'yellow';
        case 1: return 'red';
        case 2: return 'green;';
        case 3: return 'pink';
        case 4: return 'purple';
        case 5: return 'blue';
        case 6: return 'black';
        case 7: return 'orange';
        case 8: return 'lime';
        case 9: return 'white';
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
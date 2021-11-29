var pad;
var dc;
var ox = 0, oy = 0, x = 0, y = 0;
var mf = false;

function appInit() {
    pad = $("#pad")[0]
    pad.addEventListener("mousedown", onMouseDown, false);
    pad.addEventListener("mousemove", onMouseMove, false);
    pad.addEventListener("mouseup",   onMouseUp,   false);

    dc = pad.getContext("2d");
    dc.strokeStyle = "#000000";
    dc.lineWidth   = 15;
    dc.lineJoin    = "round";
    dc.lineCap     = "round";
    clearPad();
}
function onMouseDown(event) {
    ox = event.clientX - event.target.getBoundingClientRect().left;
    oy = event.clientY - event.target.getBoundingClientRect().top;
    mf = true;
}
function onMouseMove(event) {
    if (mf) {
        x = event.clientX - event.target.getBoundingClientRect().left;
        y = event.clientY - event.target.getBoundingClientRect().top;

        dc.beginPath();
        dc.moveTo(ox, oy);
        dc.lineTo(x, y);
        dc.stroke();

        ox = x;
        oy = y;
    }
}
function onMouseUp(event) {
    mf = false;
}

function clearPad() {
    dc.fillStyle = "rgb(255,255,255)";
    dc.fillRect(0, 0, pad.getBoundingClientRect().width, pad.getBoundingClientRect().height);
}

function sendImage() {
    var img = pad.toDataURL('image/jpeg');

    $.ajax({
        type: "POST",
        url: "http://localhost:5000/mnist",
        data: {
            "img": img
        },
        dataType: 'json',
    })
    .done(function(data, textStatus, jqXHR) {
        $('#answer').html('I think it\'s <span class="answer">'+data['ans']+'</span>.')
    });
}
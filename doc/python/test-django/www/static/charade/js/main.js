$(document).ready(function(){
    $("#quote").hide();
    $("#help").hide();
    $("#amount").focus();
    $("#tips1").click(function(){
        $("#quote").slideToggle("slow");
    });
    $("#tips2").click(function(){
        $("#help").fadeToggle("slow");
    });

    $("#setting").submit(function(){
        var n = $("#amount").val()
        var r = /^[0-9]*$/;
        if(!r.test(n)){
            event.preventDefault();
            alert("Digit only. '" + n + "' is not valid.");
        }
    });
});

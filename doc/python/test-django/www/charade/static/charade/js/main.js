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

    $("#ready2go").click(function(){
        var n = $("#amount").val();
        var r = /^[0-9]*$/;
        if(!n){
            event.preventDefault();
            $("#warning").text("[Error] Set the number of the words before you play.");
            $("#amount").focus();
        }
        else if (!r.test(n)){
            event.preventDefault();
            $("#warning").text("[Error] Digit only. The value you set '" + n + "' is not valid.");
            $("#amount").focus();
        }
        else {
            $("#warning").text("");
            $("#warning").text("Ready!").fadeIn(1000).fadeOut(2000,function(){
                $("#warning").text("Set!").fadeIn(1000).fadeOut(2000,function(){
                    $("#warning").text("Go!").fadeIn(1000).fadeOut(2000,function(){
                        $("#setting").submit();
                    });
                });
            });
        }
    });
});

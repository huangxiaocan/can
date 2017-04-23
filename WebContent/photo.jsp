<%@ page language="java" contentType="text/html; charset=utf-8"
    pageEncoding="utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>摄像头调用测试</title>
</head>
<body>
<video id="video" autoplay=""style='width:640px;height:480px'></video>
<div><button id='picture' style="width: 100%;">调用摄像头</button></div>
<canvas id="canvas" width="640" height="480"></canvas> 
<script type="text/javascript">
var video = document.getElementById("video");
var context = canvas.getContext("2d");
var errocb = function () {
	console.log('sth wrong!');
}
//var getUserMedia = (navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia);
if (navigator.getUserMedia) { // 标准的API
    navigator.getUserMedia({ "video": true }, function (stream) {
        video.src = stream;
        video.play();
    }, errocb);
} else if (navigator.webkitGetUserMedia) { // WebKit 核心的API
    navigator.webkitGetUserMedia({ "video": true }, function (stream) {
        video.src = window.URL.createObjectURL(stream);
        video.play();
    }, errocb);
}
document.getElementById("picture").addEventListener("click", function () {
    context.drawImage(video, 0, 0, 640, 480);
});
</script> 
</body>
</html>
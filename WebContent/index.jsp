<%@ page language="java" pageEncoding="UTF-8"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<%
	String ctx = request.getContextPath() + "/";
	pageContext.setAttribute("ctx", ctx);
%>
<html>
<head>
<link rel="canonical" href="${roomLink}" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0" />  
<meta http-equiv="X-UA-Compatible" content="chrome=1" />
<meta name="format-detection" content="telephone=no" /> 
<meta name="apple-mobile-web-app-capable" content="yes" /> 
<meta name="apple-mobile-web-app-status-bar-style" content="black">  
<meta name="author" content="huangcan@tobosoft.com.cn" />  
<script src="./js/channel.js"></script>
<script src="./js/MSRecorder.js"></script>
<script src="./js/gumadapter.js" type="text/javascript"></script>
<style type="text/css">
body{font-size:62.5%;font-family:"Microsoft YaHei",Arial; overflow-x:hidden; overflow-y:auto;}   
  
.viewport{ max-width:640px; min-width:300px; margin:0 auto;} 
a:link {
	color: #ffffff;
}

a:visited {
	color: #ffffff;
}

html,body {
	background-color: #000000;
	height: 100%;
	font-family: Verdana, Arial, Helvetica, sans-serif;
}

body {
	margin: 0;
	padding: 0;
}

#container {
	background-color: #000000;
	position: relative;
	min-height: 100%;
	width: 100%;
	margin: 0px auto;
	-webkit-perspective: 1000;
}

#card {
	-webkit-transition-property: rotation;
	-webkit-transition-duration: 2s;
	-webkit-transform-style: preserve-3d;
}

#local {
	position: absolute;
	width: 100%;
	-webkit-transform: scale(-1, 1);
	-webkit-backface-visibility: hidden;
}

#remote {
	position: absolute;
	width: 100%;
	-webkit-transform: rotateY(180deg);
	-webkit-backface-visibility: hidden;
}

#mini {
	position: absolute;
	height: 30%;
	width: 30%;
	bottom: 32px;
	right: 4px;
	-webkit-transform: scale(-1, 1);
	opacity: 1.0;
}

#localVideo {
	opacity: 0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 2s;
}

#remoteVideo {
	opacity: 0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 2s;
}

#miniVideo {
	opacity: 0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 2s;
}

#footer {
	spacing: 4px;
	position: absolute;
	bottom: 0;
	width: 100%;
	height: 28px;
	background-color: #3F3F3F;
	color: rgb(255, 255, 255);
	font-size: 13px;
	font-weight: bold;
	line-height: 28px;
	text-align: center;
}

.hangup {
	font-size: 13px;
	font-weight: bold;
	color: #FFFFFF;
	width: 128px;
	height: 24px;
	background-color: #808080;
	border-style: solid;
	border-color: #FFFFFF;
	margin: 2px;
}

#logo {
	display: block;
	top: 4;
	right: 4;
	position: absolute;
	float: right;
	opacity: 0.5;
}
</style>
</head>
<body>
	<script type="text/javascript">
		var localVideo;
		var miniVideo;
		var remoteVideo;
		var localStream;
		var remoteStream;
		var channel;
		var channelReady = false;
		var pc;
		var socket;
		var footer;
		var initiator = ${initiator};
		var started = false;
		var isRTCPeerConnection = true;
		 var mediaConstraints = {
			'mandatory':{
				'OfferToReceiveAudio' : true,
				'OfferToReceiveVideo' : true
			}
		}; 
// 		var mediaConstraints = {
// 			'has_audio' : true,
// 			'has_video' : true
// 		};
		var isVideoMuted = false;
		var isAudioMuted = false;
		var URL;
		function initialize() {
			console.log("初始化; room=${roomKey}.");
			card = document.getElementById("card");
			localVideo = document.getElementById("localVideo");
			footer = document.getElementById("footer");
			miniVideo = document.getElementById("miniVideo");
			remoteVideo = document.getElementById("remoteVideo");
			resetStatus();
			openChannel();
			getUserMedia();
			console.log("initialize1");
			URL = (window.URL || window.webkitURL || window.msURL || window.oURL);
		}
		//初始化摄像头流
		function getUserMedia() {
			navigator.getUserMedia = navigator.getUserMedia ||
            navigator.webkitGetUserMedia ||
            navigator.mozGetUserMedia; 
			if(navigator.getUserMedia){
				try {
//	 				navigator.webkitGetUserMedia({
					navigator.getUserMedia({
						"audio": true,
						"video": true
					}, onUserMediaSuccess, onUserMediaError);
					console.log("Requested access to local media with new syntax.");
				} catch (e) {
					try {
						navigator.getUserMedia("video,audio",onUserMediaSuccess, onUserMediaError);
						console.log("Requested access to local media with old syntax.");
					} catch (e) {
						alert("webkitGetUserMedia() failed. Is the MediaStream flag enabled in about:flags?");
						console.log("webkitGetUserMedia failed with exception: "+ e.message);
					}
				}
				console.log("getUserMedia2");
			}
		}
		var mediaRecorderLocalVideo;
		var mediaRecorderRemoteVideo;
		function onUserMediaSuccess(stream) {
			console.log("用户已允许访问本地媒体");
// 			var url = webkitURL.createObjectURL(stream);
			var url = URL.createObjectURL(stream);
			localVideo.style.opacity = 1;
			localVideo.src = url;
			localStream = stream;
			// Caller creates PeerConnection.
			if (initiator)
				maybeStart();
			//创建视频媒体流对象
			mediaRecorderLocalVideo = new MediaStreamRecorder(stream);
// 			mediaRecorderLocalV.videoWidth=400;
// 			mediaRecorderLocal.videoHight=400; 
		}
		
		function maybeStart() {
			if (!started && localStream && channelReady) {
				setStatus("连接中...");
				console.log("Creating PeerConnection.");
				createPeerConnection();
				console.log("Adding local stream.");
				pc.addStream(localStream);
				started = true;
				// Caller initiates offer to peer.
				if (initiator)
					doCall();
			}
		}

		function doCall() {
			console.log("Sending offer to peer.");
			if (isRTCPeerConnection) {
				pc.createOffer(setLocalAndSendMessage, function(){}, mediaConstraints);
			} else {
				var offer = pc.createOffer(mediaConstraints);
				pc.setLocalDescription(pc.SDP_OFFER, offer);
				sendMessage({
					type : 'offer',
					sdp : offer.toSdp()
				});
				pc.startIce();
			}
		}

		function setLocalAndSendMessage(sessionDescription) {
			pc.setLocalDescription(sessionDescription);
			sendMessage(sessionDescription);
		}

		function sendMessage(message) {
			var msgString = JSON.stringify(message);
			console.log('发出信息 : ' + msgString);
			path = 'message?r=${roomKey}' + '&u=${user}';
			var xhr = new XMLHttpRequest();
			xhr.open('POST', path, true);
			xhr.send(msgString);
		}

		function openChannel() {
			console.log("Opening channel.");
			socket = new WebSocket("wss://"+window.location.host+"${ctx}websocket?u=${user}");
			socket.onopen = onChannelOpened;
			socket.onmessage = onChannelMessage;
			socket.onclose = onChannelClosed;
		}

		function resetStatus() {
			if (!initiator) {
				setStatus("让别人加入视频聊天: <a href=\"${roomLink}\">${roomLink}</a>");
			} else {
				setStatus("初始化...");
			}
		}

		function createPeerConnection() {
			var pc_config = {
				"iceServers" : [ {
					"url" : "stun:stun.l.google.com:19302"
				} ]
			};
			try {
				pc = new webkitRTCPeerConnection(pc_config);

				pc.onicecandidate = onIceCandidate;
				console.log("Created webkitRTCPeerConnnection with config \""
						+ JSON.stringify(pc_config) + "\".");
			} catch (e) {
				try {
					var stun_server = "";
					if (pc_config.iceServers.length !== 0) {
						stun_server = pc_config.iceServers[0].url.replace(
								'stun:', 'STUN ');
					}
					pc = new webkitPeerConnection00(stun_server,
							onIceCandidate00);
					isRTCPeerConnection = false;
					console.log("Created webkitPeerConnnection00 with config \""
									+ stun_server + "\".");
				} catch (e) {
					console.log("Failed to create PeerConnection, exception: "
							+ e.message);
					alert("Cannot create PeerConnection object; Is the 'PeerConnection' flag enabled in about:flags?");
					return;
				}
			}

			pc.onconnecting = onSessionConnecting;
			pc.onopen = onSessionOpened;
			pc.onaddstream = onRemoteStreamAdded;
			pc.onremovestream = onRemoteStreamRemoved;
		}

		function setStatus(state) {
			footer.innerHTML = state;
		}

		function doAnswer() {
			console.log("Sending answer to peer.");
			if (isRTCPeerConnection) {
				pc.createAnswer(setLocalAndSendMessage,function(){},mediaConstraints);
// 				pc.createAnswer(setLocalAndSendMessage,function (error) {
//                     console.log('Failure callback: ' + error);
//                 });
			} else {
				var offer = pc.remoteDescription;
				var answer = pc.createAnswer(offer.toSdp(), mediaConstraints);
				pc.setLocalDescription(pc.SDP_ANSWER, answer);
				sendMessage({
					type : 'answer',
					sdp : answer.toSdp()
				});
				pc.startIce();
			}
		}

		function processSignalingMessage00(message) {
			var msg = JSON.parse(message);

			// if (msg.type == 'offer') should not happen here.
			if (msg.type == 'answer' && started) {
				pc.setRemoteDescription(pc.SDP_ANSWER, new SessionDescription(
						msg.sdp));
			} else if (msg.type == 'candidate' && started) {
				var candidate = new IceCandidate(msg.label, msg.candidate);
				pc.processIceMessage(candidate);
			} else if (msg.type == 'bye' && started) {
				onRemoteHangup();
			}
		}

		var channelOpenTime;
		var channelCloseTime;

		function onChannelOpened() {
			channelOpenTime = new Date();
			console.log("Channel opened.Open time is : "
					+ channelOpenTime.toLocaleString());
			channelReady = true;
			if (initiator)
				maybeStart();
		}
		function onChannelMessage(message) {
			console.log('收到信息 : ' + message.data);
			if (isRTCPeerConnection){
				processSignalingMessage(message.data);//建立视频连接
			}else{
				processSignalingMessage00(message.data);
			}
		}
		
		function processSignalingMessage(message) {
			var msg = JSON.parse(message);
			console.log("msg.type:"+msg.type);
			if (msg.type == 'offer') {
				// Callee creates PeerConnection
				if (!initiator && !started)
					maybeStart();

				// We only know JSEP version after createPeerConnection().
				if (isRTCPeerConnection)
					pc.setRemoteDescription(new RTCSessionDescription(msg));
				else
					pc.setRemoteDescription(pc.SDP_OFFER,new SessionDescription(msg.sdp));

				doAnswer();
			} else if (msg.type == 'answer' && started) {
				pc.setRemoteDescription(new RTCSessionDescription(msg));
			} else if (msg.type == 'candidate' && started) {
				var nativeRTCIceCandidate = (window.mozRTCIceCandidate || window.RTCIceCandidate);
				var candidate = new nativeRTCIceCandidate({
					sdpMLineIndex : msg.label,
					candidate : msg.candidate
				});
				pc.addIceCandidate(candidate);
			} else if (msg.type == 'bye' && started) {
				onRemoteHangup();
			}
		}
		
		function onChannelError() {
			console.log('Channel error');
		}
		function onChannelClosed() {
			if(!channelOpenTime){
				channelOpenTime = new Date();
			}
			channelCloseTime = new Date();
			console.log("Channel closed.Close time is "
							+ channelOpenTime.toLocaleString()
							+ " ,Keep time : "
							+ ((channelCloseTime.getTime() - channelOpenTime
									.getTime()) / 1000 + "s"));
			openChannel();
		}

		function onUserMediaError(error) {
			console.log("Failed to get access to local media. Error code was "+ error.code);
			alert("Failed to get access to local media. Error code was "+ error.code + ".");
		}

		function onIceCandidate(event) {
			if (event.candidate) {
				sendMessage({
					type : 'candidate',
					label : event.candidate.sdpMLineIndex,
					id : event.candidate.sdpMid,
					candidate : event.candidate.candidate
				});
			} else {
				console.log("End of candidates.");
			}
		}

		function onIceCandidate00(candidate, moreToFollow) {
			if (candidate) {
				sendMessage({
					type : 'candidate',
					label : candidate.label,
					candidate : candidate.toSdp()
				});
			}

			if (!moreToFollow) {
				console.log("End of candidates.");
			}
		}

		function onSessionConnecting(message) {
			console.log("Session connecting.");
		}
		function onSessionOpened(message) {
			console.log("Session opened.");
		}

		function onRemoteStreamAdded(event) {
			console.log("Remote stream added.");
// 			var url = webkitURL.createObjectURL(event.stream);
            var url = URL.createObjectURL(event.stream);
			miniVideo.src = localVideo.src;
			remoteVideo.src = url;
			remoteStream = event.stream;
			mediaRecorderRemoteVideo = new MediaStreamRecorder(remoteStream);
			mediaRecorderRemoteVideo.mimeType="video/webm";
			startRecording();
			waitForRemoteVideo();
		}
		function onRemoteStreamRemoved(event) {
			console.log("Remote stream removed.");
		}

		function onHangup() {
			stopRecording();
			console.log("Hanging up.");
			transitionToDone();
			stop();
			socket.close();
		}

		function onRemoteHangup() {
			console.log('Session terminated.');
			transitionToWaiting();
			stop();
			initiator = 0;
		}

		function stop() {
			started = false;
			isRTCPeerConnection = true;
			isAudioMuted = false;
			isVideoMuted = false;
			pc.close();
			pc = null;
		}

		function waitForRemoteVideo() {
			if (remoteStream.getVideoTracks().length == 1 || remoteVideo.currentTime > 0) {
				transitionToActive();
			} else {
				setTimeout(waitForRemoteVideo, 100);
			}
		}
		function transitionToActive() {
			remoteVideo.style.opacity = 1;
			card.style.webkitTransform = "rotateY(180deg)";
			setTimeout(function() {
				localVideo.src = "";
			}, 500);
			setTimeout(function() {
				miniVideo.style.opacity = 1;
			}, 1000);
			setStatus("<input type=\"button\" class=\"hangup\" value=\"结束通话\" onclick=\"onHangup()\" />");
			//<input type=\"button\" class=\"hangup\" value='开始录制' onclick=\"startRecording()\" /> <input type=\"button\" class=\"hangup\" value='结束录制' onclick=\"stopRecording()\"/><input type=\"button\" class=\"hangup\" value='下载视频' onclick=\"saveRecording()\"/>
		}
		function transitionToWaiting() {
			card.style.webkitTransform = "rotateY(0deg)";
			setTimeout(function() {
				console.log("transitionToWaiting");				
				localVideo.src = miniVideo.src;
				miniVideo.src = "";
				remoteVideo.src = ""
			}, 500);
			miniVideo.style.opacity = 0;
			remoteVideo.style.opacity = 0;
			resetStatus();
		}
		function transitionToDone() {
			localVideo.style.opacity = 0;
			remoteVideo.style.opacity = 0;
			miniVideo.style.opacity = 0;
			setStatus("You have left the call. <a href=\"${roomLink}\">Click here</a> to rejoin.");
		}
		function enterFullScreen() {
			container.webkitRequestFullScreen();
		}

		function toggleVideoMute() {
			if (localStream.getVideoTracks().length == 0) {
				console.log("No local video available.");
				return;
			}

			if (isVideoMuted) {
				for (i = 0; i < localStream.getVideoTracks().length; i++) {
					localStream.getVideoTracks[i].enabled = true;
				}
				console.log("Video unmuted.");
			} else {
				for (i = 0; i < localStream.getVideoTracks().length; i++) {
					localStream.getVideoTracks[i].enabled = false;
				}
				console.log("Video muted.");
			}

			isVideoMuted = !isVideoMuted;
		}

		function toggleAudioMute() {
			if (localStream.getAudioTracks().length == 0) {
				console.log("No local audio available.");
				return;
			}

			if (isAudioMuted) {
				for (i = 0; i < localStream.getAudioTracks().length; i++) {
					localStream.audioTracks[i].enabled = true;
				}
				console.log("Audio unmuted.");
			} else {
				for (i = 0; i < localStream.getAudioTracks().length; i++) {
					localStream.getAudioTracks()[i].enabled = false;
				}
				console.log("Audio muted.");
			}

			isAudioMuted = !isAudioMuted;
		}

		setTimeout(initialize, 1);

		// Send BYE on refreshing(or leaving) a demo page
		// to ensure the room is cleaned for next session.
		window.onbeforeunload = function() {
			sendMessage({
				type : 'bye'
			});
		}

		// Ctrl-D: toggle audio mute; Ctrl-E: toggle video mute.
		// On Mac, Command key is instead of Ctrl.
		// Return false to screen out original Chrome shortcuts.
		document.onkeydown = function() {
			if (navigator.appVersion.indexOf("Mac") != -1) {
				if (event.metaKey && event.keyCode == 68) {
					toggleAudioMute();
					return false;
				}
				if (event.metaKey && event.keyCode == 69) {
					toggleVideoMute();
					return false;
				}
			} else {
				if (event.ctrlKey && event.keyCode == 68) {
					toggleAudioMute();
					return false;
				}
				if (event.ctrlKey && event.keyCode == 69) {
					toggleVideoMute();
					return false;
				}
			}
		}
		//开启录像
// 		var recorder, videoTrack;
// 		var recorderFile, stopRecordCallback;
		function startRecording(){
			console.log("开启录制本地录像");	
			mediaRecorderLocalVideo.start(1000*1000);
			console.log("开启录制远程录像");
			mediaRecorderRemoteVideo.start(1000*1000);
// 			recorder = new MediaRecorder(remoteStream);
// 			videoTrack = remoteStream.getVideoTracks()[0];
// 			var chunks = [], startTime = 0;
//             recorder.ondataavailable = function(e) {
//                 chunks.push(e.data);
//             };
//             recorder.onstop = function (e) {
//                 recorderFile = new Blob(chunks, { 'type' : recorder.mimeType });
//                 chunks = [];
//                 if (null != stopRecordCallback) {
//                 	stopRecordCallback();
//                 }
//             };
//             recorder.start();
		}
		// 停止录制
		function stopRecording(){
			mediaRecorderLocalVideo.stop();
			mediaRecorderRemoteVideo.stop();
			console.log("执行stop");
			//等待3秒执行保存方法
			setTimeout(saveRecording,3000);
			console.log("执行save");
		}
		//下载录制视频
		function saveRecording(){
			mediaRecorderLocalVideo.save();
			mediaRecorderRemoteVideo.save();
		}
// 		function stopRecord(callback) {
// 			console.log("停止录制");			
// // 		    stopRecordCallback = callback;
// // 		    recorder.stop();
// // 		    videoTrack.stop();
// 		}

		// 播放录制的音频
		function playRecord() {
// 		    var url = URL.createObjectURL(recorderFile);
// 		    miniVideo.autoplay = true;
// 		    miniVideo.src = url;
		}
		//视频窗口切换
		function videoTran(){
			var changeUrl = miniVideo.src;
			miniVideo.src = remoteVideo.src;
			remoteVideo.src = changeUrl;
		}
	</script>
	<div id="container" ondblclick="enterFullScreen()">
		<div id="card">
			<div id="local">
				<video width="100%" height="100%" id="localVideo" autoplay="autoplay" />
			</div>
			<div id="remote">
				<video width="100%" height="100%" id="remoteVideo" autoplay="autoplay" onclick="videoTran();"></video>
				<div id="mini">
					<video width="100%" height="100%" id="miniVideo" autoplay="autoplay" onclick="videoTran();"/>
				</div>
			</div>
		</div>
		<div id="footer"></div>
		<a href="http://www.webrtc.org"><img id="logo" alt="WebRTC" src="${ctx}images/webrtc_black_20p.png"> </a>
	</div>
</body>
</html>

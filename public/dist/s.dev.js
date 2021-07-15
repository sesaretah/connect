"use strict";

// We make use of this 'server' variable to provide the address of the
// REST Janus API. By default, in this example we assume that Janus is
// co-located with the web server hosting the HTML pages but listening
// on a different port (8088, the default for HTTP in Janus), which is
// why we make use of the 'window.location.hostname' base address. Since
// Janus can also do HTTPS, and considering we don't really want to make
// use of HTTP for Janus if your demos are served on HTTPS, we also rely
// on the 'window.location.protocol' prefix to build the variable, in
// particular to also change the port used to contact Janus (8088 for
// HTTP and 8089 for HTTPS, if enabled).
// In case you place Janus behind an Apache frontend (as we did on the
// online demos at http://janus.conf.meetecho.com) you can just use a
// relative path for the variable, e.g.:
//
// 		var server = "/janus";
//
// which will take care of this on its own.
//
//
// If you want to use the WebSockets frontend to Janus, instead, you'll
// have to pass a different kind of address, e.g.:
//
// 		var server = "ws://" + window.location.hostname + ":8188";
//
// Of course this assumes that support for WebSockets has been built in
// when compiling the server. WebSockets support has not been tested
// as much as the REST API, so handle with care!
//
//
// If you have multiple options available, and want to let the library
// autodetect the best way to contact your server (or pool of servers),
// you can also pass an array of servers, e.g., to provide alternative
// means of access (e.g., try WebSockets first and, if that fails, fall
// back to plain HTTP) or just have failover servers:
//
//		var server = [
//			"ws://" + window.location.hostname + ":8188",
//			"/janus"
//		];
//
// This will tell the library to try connecting to each of the servers
// in the presented order. The first working server will be used for
// the whole session.
//
var server = "https://sync.ut.ac.ir:8089/janus";
var janus = null;
var sfutest = null;
var opaqueId = "videoroomtest-" + Janus.randomString(12);
var myroom = 1234; // Demo room

if (getQueryStringValue("room") !== "") myroom = parseInt(getQueryStringValue("room"));
var myusername = null;
var myid = null;
var mystream = null; // We use this other ID just to map our subscriptions to us

var mypvtid = null;
var feeds = [];
var bitrateTimer = [];
var streams = [];
var doSimulcast = getQueryStringValue("simulcast") === "yes" || getQueryStringValue("simulcast") === "true";
var doSimulcast2 = getQueryStringValue("simulcast2") === "yes" || getQueryStringValue("simulcast2") === "true";
var acodec = getQueryStringValue("acodec") !== "" ? getQueryStringValue("acodec") : null;
var vcodec = getQueryStringValue("vcodec") !== "" ? getQueryStringValue("vcodec") : null;
var subscriber_mode = getQueryStringValue("subscriber-mode") === "yes" || getQueryStringValue("subscriber-mode") === "true";
$(document).ready(function () {
  // Initialize the library (all console debuggers enabled)
  Janus.init({
    debug: "all",
    callback: function callback() {
      // Use a button to start the demo
      // Make sure the browser supports WebRTC
      if (!Janus.isWebrtcSupported()) {
        alert("No WebRTC support... ");
        return;
      } // Create session


      janus = new Janus({
        server: server,
        success: function success() {
          // Attach to VideoRoom plugin
          janus.attach({
            plugin: "janus.plugin.videoroom",
            opaqueId: opaqueId,
            success: function success(pluginHandle) {
              $("#details").remove();
              sfutest = pluginHandle;
              Janus.log("Plugin attached! (" + sfutest.getPlugin() + ", id=" + sfutest.getId() + ")");
              Janus.log("  -- This is a publisher/manager"); // Prepare the username registration

              registerUsername();
            },
            error: function error(_error) {
              Janus.error("  -- Error attaching plugin...", _error);
              alert("Error attaching plugin... " + _error);
            },
            consentDialog: function consentDialog(on) {
              Janus.debug("Consent dialog should be " + (on ? "on" : "off") + " now");
            },
            iceState: function iceState(state) {
              Janus.log("ICE state changed to " + state);
            },
            mediaState: function mediaState(medium, on) {
              Janus.log("Janus " + (on ? "started" : "stopped") + " receiving our " + medium);
            },
            webrtcState: function webrtcState(on) {
              Janus.log("Janus says our WebRTC PeerConnection is " + (on ? "up" : "down") + " now");
            },
            onmessage: function onmessage(msg, jsep) {
              Janus.debug(" ::: Got a message (publisher) :::", msg);
              var event = msg["videoroom"];
              Janus.debug("Event: " + event);

              if (event) {
                if (event === "joined") {
                  // Publisher/manager created, negotiate WebRTC and attach to existing feeds, if any
                  myid = msg["id"];
                  mypvtid = msg["private_id"];
                  Janus.log("Successfully joined room " + msg["room"] + " with ID " + myid);

                  if (subscriber_mode) {
                    $("#videojoin").hide();
                    $("#videos").removeClass("hide").show();
                  } else {} //publishOwnFeed(true);
                  // Any new feed to attach to?


                  if (msg["publishers"]) {
                    var list = msg["publishers"];
                    Janus.debug("Got a list of available publishers/feeds:", list);

                    for (var f in list) {
                      var id = list[f]["id"];
                      var display = list[f]["display"];
                      var audio = list[f]["audio_codec"];
                      var video = list[f]["video_codec"];
                      Janus.debug("  >> [" + id + "] " + display + " (audio: " + audio + ", video: " + video + ")");
                      newRemoteFeed(id, display, audio, video);
                    }
                  }
                } else if (event === "destroyed") {
                  // The room has been destroyed
                  Janus.warn("The room has been destroyed!");
                  alert("The room has been destroyed", function () {
                    window.location.reload();
                  });
                } else if (event === "event") {
                  // Any new feed to attach to?
                  if (msg["publishers"]) {
                    var list = msg["publishers"];
                    Janus.debug("Got a list of available publishers/feeds:", list);

                    for (var f in list) {
                      var id = list[f]["id"];
                      var display = list[f]["display"];
                      var audio = list[f]["audio_codec"];
                      var video = list[f]["video_codec"];
                      Janus.debug("  >> [" + id + "] " + display + " (audio: " + audio + ", video: " + video + ")");
                      newRemoteFeed(id, display, audio, video);
                    }
                  } else if (msg["leaving"]) {
                    // One of the publishers has gone away?
                    var leaving = msg["leaving"];
                    Janus.log("Publisher left: " + leaving);
                    var remoteFeed = null;

                    for (var i = 1; i < 6; i++) {
                      if (feeds[i] && feeds[i].rfid == leaving) {
                        remoteFeed = feeds[i];
                        break;
                      }
                    }

                    if (remoteFeed != null) {
                      Janus.debug("Feed " + remoteFeed.rfid + " (" + remoteFeed.rfdisplay + ") has left the room, detaching");
                      $("#remote" + remoteFeed.rfindex).empty().hide();
                      $("#videoremote" + remoteFeed.rfindex).empty();
                      feeds[remoteFeed.rfindex] = null;
                      remoteFeed.detach();
                    }
                  } else if (msg["unpublished"]) {
                    // One of the publishers has unpublished?
                    var unpublished = msg["unpublished"];
                    Janus.log("Publisher left: " + unpublished);

                    if (unpublished === "ok") {
                      // That's us
                      sfutest.hangup();
                      return;
                    }

                    var remoteFeed = null;

                    for (var i = 1; i < 6; i++) {
                      if (feeds[i] && feeds[i].rfid == unpublished) {
                        remoteFeed = feeds[i];
                        break;
                      }
                    }

                    if (remoteFeed != null) {
                      Janus.debug("Feed " + remoteFeed.rfid + " (" + remoteFeed.rfdisplay + ") has left the room, detaching");
                      $("#remote" + remoteFeed.rfindex).empty().hide();
                      $("#videoremote" + remoteFeed.rfindex).empty();
                      feeds[remoteFeed.rfindex] = null;
                      remoteFeed.detach();
                    }
                  } else if (msg["error"]) {
                    if (msg["error_code"] === 426) {
                      // This is a "no such room" error: give a more meaningful description
                      alert("<p>Apparently room <code>" + myroom + "</code> (the one this demo uses as a test room) " + "does not exist...</p><p>Do you have an updated <code>janus.plugin.videoroom.jcfg</code> " + "configuration file? If not, make sure you copy the details of room <code>" + myroom + "</code> " + "from that sample in your current configuration file, then restart Janus and try again.");
                    } else {
                      alert(msg["error"]);
                    }
                  }
                }
              }

              if (jsep) {
                Janus.debug("Handling SDP as well...", jsep);
                sfutest.handleRemoteJsep({
                  jsep: jsep
                }); // Check if any of the media we wanted to publish has
                // been rejected (e.g., wrong or unsupported codec)

                var audio = msg["audio_codec"];

                if (mystream && mystream.getAudioTracks() && mystream.getAudioTracks().length > 0 && !audio) {
                  // Audio has been rejected
                  toastr.warning("Our audio stream has been rejected, viewers won't hear us");
                }

                var video = msg["video_codec"];

                if (mystream && mystream.getVideoTracks() && mystream.getVideoTracks().length > 0 && !video) {
                  // Video has been rejected
                  toastr.warning("Our video stream has been rejected, viewers won't see us"); // Hide the webcam video

                  $("#myvideo").hide();
                  $("#videolocal").append('<div class="no-video-container">' + '<i class="fa fa-video-camera fa-5 no-video-icon" style="height: 100%;"></i>' + '<span class="no-video-text" style="font-size: 16px;">Video rejected, no webcam</span>' + "</div>");
                }
              }
            },
            onlocalstream: function onlocalstream(stream) {
              Janus.debug(" ::: Got a local stream :::", stream);
              mystream = stream;
              $("#videojoin").hide();
              $("#videos").removeClass("hide").show();

              if ($("#myvideo").length === 0) {
                $("#videolocal").append('<video class="rounded centered" id="myvideo" width="100%" height="100%" autoplay playsinline muted="muted"/>'); // Add a 'mute' button

                $("#videolocal").append('<button class="btn btn-warning btn-xs" id="mute" style="position: absolute; bottom: 0px; left: 0px; margin: 15px;">Mute</button>');
                $("#mute").click(toggleMute); // Add an 'unpublish' button

                $("#videolocal").append('<button class="btn btn-warning btn-xs" id="unpublish" style="position: absolute; bottom: 0px; right: 0px; margin: 15px;">Unpublish</button>');
                $("#unpublish").click(unpublishOwnFeed);
              }

              $("#publisher").removeClass("hide").html(myusername).show();
              Janus.attachMediaStream($("#myvideo").get(0), stream);
              $("#myvideo").get(0).muted = "muted";

              if (sfutest.webrtcStuff.pc.iceConnectionState !== "completed" && sfutest.webrtcStuff.pc.iceConnectionState !== "connected") {
                $("#videolocal").parent().parent().block({
                  message: "<b>Publishing...</b>",
                  css: {
                    border: "none",
                    backgroundColor: "transparent",
                    color: "white"
                  }
                });
              }

              var videoTracks = stream.getVideoTracks();

              if (!videoTracks || videoTracks.length === 0) {
                // No webcam
                $("#myvideo").hide();

                if ($("#videolocal .no-video-container").length === 0) {
                  $("#videolocal").append('<div class="no-video-container">' + '<i class="fa fa-video-camera fa-5 no-video-icon"></i>' + '<span class="no-video-text">No webcam available</span>' + "</div>");
                }
              } else {
                $("#videolocal .no-video-container").remove();
                $("#myvideo").removeClass("hide").show();
              }
            },
            onremotestream: function onremotestream(stream) {// The publisher stream is sendonly, we don't expect anything here
            },
            oncleanup: function oncleanup() {
              Janus.log(" ::: Got a cleanup notification: we are unpublished now :::");
              mystream = null;
              $("#videolocal").html('<button id="publish" class="btn btn-primary">Publish</button>');
              $("#publish").click(function () {
                publishOwnFeed(true);
              });
              $("#videolocal").parent().parent().unblock();
              $("#bitrate").parent().parent().addClass("hide");
              $("#bitrate a").unbind("click");
            }
          });
        },
        error: function error(_error2) {
          Janus.error(_error2);
          alert(_error2, function () {
            window.location.reload();
          });
        },
        destroyed: function destroyed() {
          window.location.reload();
        }
      });
    }
  });
});

function checkEnter(field, event) {
  var theCode = event.keyCode ? event.keyCode : event.which ? event.which : event.charCode;

  if (theCode == 13) {
    registerUsername();
    return false;
  } else {
    return true;
  }
}

function registerUsername() {
  var register = {
    request: "join",
    room: myroom,
    ptype: "publisher",
    display: "broadcaster"
  };
  myusername = "broadcaster";
  sfutest.send({
    message: register
  });
}

function publishOwnFeed(useAudio) {
  // Publish our stream
  $("#publish").attr("disabled", true).unbind("click");
  sfutest.createOffer({
    // Add data:true here if you want to publish datachannels as well
    media: {
      audioRecv: false,
      videoRecv: false,
      audioSend: useAudio,
      videoSend: true
    },
    // Publishers are sendonly
    // If you want to test simulcasting (Chrome and Firefox only), then
    // pass a ?simulcast=true when opening this demo page: it will turn
    // the following 'simulcast' property to pass to janus.js to true
    simulcast: doSimulcast,
    simulcast2: doSimulcast2,
    success: function success(jsep) {
      Janus.debug("Got publisher SDP!", jsep);
      var publish = {
        request: "configure",
        audio: useAudio,
        video: true
      }; // You can force a specific codec to use when publishing by using the
      // audiocodec and videocodec properties, for instance:
      // 		publish["audiocodec"] = "opus"
      // to force Opus as the audio codec to use, or:
      // 		publish["videocodec"] = "vp9"
      // to force VP9 as the videocodec to use. In both case, though, forcing
      // a codec will only work if: (1) the codec is actually in the SDP (and
      // so the browser supports it), and (2) the codec is in the list of
      // allowed codecs in a room. With respect to the point (2) above,
      // refer to the text in janus.plugin.videoroom.jcfg for more details.
      // We allow people to specify a codec via query string, for demo purposes

      if (acodec) publish["audiocodec"] = acodec;
      if (vcodec) publish["videocodec"] = vcodec;
      sfutest.send({
        message: publish,
        jsep: jsep
      });
    },
    error: function error(_error3) {
      Janus.error("WebRTC error:", _error3);

      if (useAudio) {
        publishOwnFeed(false);
      } else {
        alert("WebRTC error... " + _error3.message);
        $("#publish").removeAttr("disabled").click(function () {
          publishOwnFeed(true);
        });
      }
    }
  });
}

function toggleMute() {
  var muted = sfutest.isAudioMuted();
  Janus.log((muted ? "Unmuting" : "Muting") + " local stream...");
  if (muted) sfutest.unmuteAudio();else sfutest.muteAudio();
  muted = sfutest.isAudioMuted();
  $("#mute").html(muted ? "Unmute" : "Mute");
}

function unpublishOwnFeed() {
  // Unpublish our stream
  $("#unpublish").attr("disabled", true).unbind("click");
  var unpublish = {
    request: "unpublish"
  };
  sfutest.send({
    message: unpublish
  });
}

function newRemoteFeed(id, display, audio, video) {
  console.log(id, display, audio, video); // A new feed has been published, create a new plugin handle and attach to it as a subscriber

  var remoteFeed = null;
  janus.attach({
    plugin: "janus.plugin.videoroom",
    opaqueId: opaqueId,
    success: function success(pluginHandle) {
      remoteFeed = pluginHandle;
      remoteFeed.simulcastStarted = false;
      Janus.log("Plugin attached! (" + remoteFeed.getPlugin() + ", id=" + remoteFeed.getId() + ")");
      Janus.log("  -- This is a subscriber"); // We wait for the plugin to send us an offer

      var subscribe = {
        request: "join",
        room: myroom,
        ptype: "subscriber",
        feed: id,
        private_id: mypvtid
      }; // In case you don't want to receive audio, video or data, even if the
      // publisher is sending them, set the 'offer_audio', 'offer_video' or
      // 'offer_data' properties to false (they're true by default), e.g.:
      // 		subscribe["offer_video"] = false;
      // For example, if the publisher is VP8 and this is Safari, let's avoid video

      if (Janus.webRTCAdapter.browserDetails.browser === "safari" && (video === "vp9" || video === "vp8" && !Janus.safariVp8)) {
        if (video) video = video.toUpperCase();
        toastr.warning("Publisher is using " + video + ", but Safari doesn't support it: disabling video");
        subscribe["offer_video"] = false;
      }

      remoteFeed.videoCodec = video; // roomId = display.split("§")[display.split("§").length - 1]
      // if(getUrlVars()["display"] === roomId[0]) {

      remoteFeed.send({
        message: subscribe
      }); //}
    },
    error: function error(_error4) {
      Janus.error("  -- Error attaching plugin...", _error4);
      alert("Error attaching plugin... " + _error4);
    },
    onmessage: function onmessage(msg, jsep) {
      Janus.debug(" ::: Got a message (subscriber) :::", msg);
      var event = msg["videoroom"];
      Janus.debug("Event: " + event);

      if (msg["error"]) {
        alert(msg["error"]);
      } else if (event) {
        if (event === "attached") {
          // Subscriber created and attached
          for (var i = 1; i < 6; i++) {
            if (!feeds[i]) {
              feeds[i] = remoteFeed;
              remoteFeed.rfindex = i;
              break;
            }
          }

          remoteFeed.rfid = msg["id"];
          remoteFeed.rfdisplay = msg["display"];
          /*
                if (!remoteFeed.spinner) {
                  var target = document.getElementById(
                    "videoremote" + remoteFeed.rfindex
                  );
                  remoteFeed.spinner = new Spinner({ top: 100 }).spin(target);
                } else {
                  remoteFeed.spinner.spin();
                }*/

          Janus.log("Successfully attached to feed " + remoteFeed.rfid + " (" + remoteFeed.rfdisplay + ") in room " + msg["room"]);
          $("#remote" + remoteFeed.rfindex).removeClass("hide").html(remoteFeed.rfdisplay).show();
        } else if (event === "event") {
          // Check if we got a simulcast-related event from this publisher
          var substream = msg["substream"];
          var temporal = msg["temporal"];

          if (substream !== null && substream !== undefined || temporal !== null && temporal !== undefined) {
            if (!remoteFeed.simulcastStarted) {
              remoteFeed.simulcastStarted = true; // Add some new buttons

              addSimulcastButtons(remoteFeed.rfindex, remoteFeed.videoCodec === "vp8");
            } // We just received notice that there's been a switch, update the buttons


            updateSimulcastButtons(remoteFeed.rfindex, substream, temporal);
          }
        } else {// What has just happened?
        }
      }

      if (jsep) {
        Janus.debug("Handling SDP as well...", jsep); // Answer and attach

        remoteFeed.createAnswer({
          jsep: jsep,
          // Add data:true here if you want to subscribe to datachannels as well
          // (obviously only works if the publisher offered them in the first place)
          media: {
            audioSend: false,
            videoSend: false
          },
          // We want recvonly audio/video
          success: function success(jsep) {
            Janus.debug("Got SDP!", jsep);
            var body = {
              request: "start",
              room: myroom
            };
            remoteFeed.send({
              message: body,
              jsep: jsep
            });
          },
          error: function error(_error5) {
            Janus.error("WebRTC error:", _error5);
            alert("WebRTC error... " + _error5.message);
          }
        });
      }
    },
    iceState: function iceState(state) {
      Janus.log("ICE state of this WebRTC PeerConnection (feed #" + remoteFeed.rfindex + ") changed to " + state);
    },
    webrtcState: function webrtcState(on) {
      Janus.log("Janus says this WebRTC PeerConnection (feed #" + remoteFeed.rfindex + ") is " + (on ? "up" : "down") + " now");
    },
    onlocalstream: function onlocalstream(stream) {// The subscriber stream is recvonly, we don't expect anything here
    },
    onremotestream: function onremotestream(stream) {
      streamAttacher(remoteFeed, display);
      streams.push(remoteFeed.id); //console.log('^^^^^^^^^^^^^', remoteFeed)
      //console.log("Remote feed #" + remoteFeed.rfindex + ", stream:", stream);

      /*
         var addButtons = false;
         if ($("#remotevideo" + remoteFeed.rfindex).length === 0) {
           addButtons = true;
           // No remote video yet
           $("#videoremote" + remoteFeed.rfindex).append(
             '<video class="rounded centered" id="waitingvideo' +
               remoteFeed.rfindex +
               '" width="100%" height="100%" />'
           );
           $("#videoremote" + remoteFeed.rfindex).append(
             '<video class="rounded centered relative hide" id="remotevideo' +
               remoteFeed.rfindex +
               '" width="100%" height="100%" autoplay playsinline/>'
           );
           $("#videoremote" + remoteFeed.rfindex).append(
             '<span class="label label-primary hide" id="curres' +
               remoteFeed.rfindex +
               '" style="position: absolute; bottom: 0px; left: 0px; margin: 15px;"></span>' +
               '<span class="label label-info hide" id="curbitrate' +
               remoteFeed.rfindex +
               '" style="position: absolute; bottom: 0px; right: 0px; margin: 15px;"></span>'
           );
           // Show the video, hide the spinner and show the resolution when we get a playing event
           $("#remotevideo" + remoteFeed.rfindex).bind("playing", function () {
             if (remoteFeed.spinner) remoteFeed.spinner.stop();
             remoteFeed.spinner = null;
             $("#waitingvideo" + remoteFeed.rfindex).remove();
             if (this.videoWidth)
               $("#remotevideo" + remoteFeed.rfindex)
                 .removeClass("hide")
                 .show();
             var width = this.videoWidth;
             var height = this.videoHeight;
             $("#curres" + remoteFeed.rfindex)
               .removeClass("hide")
               .text(width + "x" + height)
               .show();
             if (Janus.webRTCAdapter.browserDetails.browser === "firefox") {
               // Firefox Stable has a bug: width and height are not immediately available after a playing
               setTimeout(function () {
                 var width = $("#remotevideo" + remoteFeed.rfindex).get(
                   0
                 ).videoWidth;
                 var height = $("#remotevideo" + remoteFeed.rfindex).get(
                   0
                 ).videoHeight;
                 $("#curres" + remoteFeed.rfindex)
                   .removeClass("hide")
                   .text(width + "x" + height)
                   .show();
               }, 2000);
             }
           });
         }*/
    },
    oncleanup: function oncleanup() {
      Janus.log(" ::: Got a cleanup notification (remote feed " + id + ") :::");
      roomId = display.split("§")[display.split("§").length - 1];
      console.log(roomId, id);
      $("#video-" + id).remove();
      socket.emit('ionRelSlot', {
        slot: roomId,
        stream: id
      });
      streams = streams.filter(function (item) {
        return item !== id;
      }); //if (remoteFeed.spinner) remoteFeed.spinner.stop();
      //remoteFeed.spinner = null;
      //$("#remotevideo" + remoteFeed.rfindex).remove();
      //$("#waitingvideo" + remoteFeed.rfindex).remove();
      //$("#novideo" + remoteFeed.rfindex).remove();
      //$("#curbitrate" + remoteFeed.rfindex).remove();
      //$("#curres" + remoteFeed.rfindex).remove();
      //if (bitrateTimer[remoteFeed.rfindex])
      // clearInterval(bitrateTimer[remoteFeed.rfindex]);
      //bitrateTimer[remoteFeed.rfindex] = null;
      //remoteFeed.simulcastStarted = false;
      //$("#simulcast" + remoteFeed.rfindex).remove();
    }
  });
} // Helper to parse query string


function getQueryStringValue(name) {
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
  var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
      results = regex.exec(location.search);
  return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
} // Helpers to create Simulcast-related UI, if enabled


function addSimulcastButtons(feed, temporal) {}

function updateSimulcastButtons(feed, substream, temporal) {}

function streamAttacher(feed, display) {
  roomId = display.split("§")[display.split("§").length - 1];
  console.log("Attaching " + feed.id);
  console.log($("#video-" + feed.id).length);

  if ($("#video-" + feed.id).length === 0) {
    var localVideo = document.createElement("video");
    localVideo.autoplay = true;
    localVideo.muted = true;
    localVideo.width = "320";
    localVideo.id = "video-" + feed.id;
  }

  if (feed.id && feed.webrtcStuff && feed.webrtcStuff.remoteStream) {
    //$("#v"+roomId[1]).html();
    if ($("#" + feed.id).length === 0) {
      $("#remotes").append("<div id='" + feed.id + "' class='v'></div>");
      placeVideo();
    }

    $("#" + feed.id).prepend(localVideo);
    Janus.attachMediaStream(document.getElementById("video-" + feed.id), feed.webrtcStuff.remoteStream);
  }
}

function placeVideo() {
  items = streams.length;
  var id = Math.random().toString(36).substring(7);

  if (items < 7) {
    $(".v").each(function () {
      $(this).addClass('col-md-4');
      $(this).addClass('hv-50');
    });
  }

  if (items > 6 && items < 17) {
    $(".v").each(function () {
      $(this).removeClass('col-md-4');
      $(this).removeClass('hv-50');
      $(this).addClass('col-md-3');
      $(this).addClass('hv-25');
    });
  }

  if (items > 16 && items < 37) {
    $(".v").each(function () {
      $(this).removeClass('col-md-3');
      $(this).removeClass('hv-25');
      $(this).addClass('col-md-2');
      $(this).addClass('hv-16');
    });
  }
}
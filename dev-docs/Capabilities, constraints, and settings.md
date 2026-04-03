Overview
The process works like this (using MediaStreamTrack as an example):

If needed, call MediaDevices.getSupportedConstraints() to get the list of supported constraints, which tells you what constrainable properties the browser knows about. This isn't always necessary, since any that aren't known will be ignored when you specify them—but if you have any that you can't get by without, you can start by checking to be sure they're on the list.
Once the script knows whether the property or properties it wishes to use are supported, it can then check the capabilities of the API and its implementation by examining the object returned by the track's getCapabilities() method; this object lists each supported constraint and the values or range of values which are supported.
Finally, the track's applyConstraints() method is called to configure the API as desired by specifying the values or ranges of values it wishes to use for any of the constrainable properties about which it has a preference.
The track's getConstraints() method returns the set of constraints passed into the most recent call to applyConstraints(). This may not represent the actual current state of the track, due to properties whose requested values had to be adjusted and because platform default values aren't represented. For a complete representation of the track's current configuration, use getSettings().
In the Media Capture and Streams API, both MediaStream and MediaStreamTrack have constrainable properties.

Determining if a constraint is supported
If you need to know whether or not a given constraint is supported by the user agent, you can find out by calling navigator.mediaDevices.getSupportedConstraints() to get a list of the constrainable properties which the browser knows, like this:

js

Copy
const supported = navigator.mediaDevices.getSupportedConstraints();

document.getElementById("frameRateSlider").disabled = !supported["frameRate"];
In this example, the supported constraints are fetched, and a control that lets the user configure the frame rate is disabled if the frameRate constraint isn't supported.

How constraints are defined
A single constraint is an object whose name matches the constrainable property whose desired value or range of values is being specified. This object contains zero or more individual constraints, as well as an optional sub-object named advanced, which contains another set of zero or more constraints which the user agent must satisfy if at all possible. The user agent attempts to satisfy constraints in the order specified in the constraint set.

The most important thing to understand is that most constraints aren't requirements; instead, they're requests. There are exceptions, and we'll get to those shortly.

Requesting a specific value for a setting
Most, each constraint may be a specific value indicating a desired value for the setting. For example:

js

Copy
const constraints = {
  width: 1920,
  height: 1080,
  aspectRatio: 1.777777778,
};

myTrack.applyConstraints(constraints);
In this case, the constraints indicate that any values are fine for nearly all properties, but that a standard high definition (HD) video size is desired, with the standard 16:9 aspect ratio. There's no guarantee that the resulting track will match any of these, but the user agent should do its best to match as many as possible.

The prioritization of the properties is simple: if two properties' requested values are mutually exclusive, then the one listed first in the constraint set will be used. As an example, if the browser running the code above couldn't provide a 1920x1080 track but could do 1920x900, then that's what would be provided.

Simple constraints like these, specifying a single value, are always treated as non-required. The user agent will try to provide what you request but will not guarantee that what you get will match. However, if you use simple values for properties when calling MediaStreamTrack.applyConstraints(), the request will always succeed, because these values will be considered a request, not a requirement.

Specifying a range of values
Sometimes, any value within a range is acceptable for a property's value. You can specify ranges with either or both minimum and maximum values, and you can even specify an ideal value within the range, if you choose. If you provide an ideal value, the browser will try to get as close as possible to matching that value, given the other constraints specified.

js

Copy
const supports = navigator.mediaDevices.getSupportedConstraints();

if (
  !supports["width"] ||
  !supports["height"] ||
  !supports["frameRate"] ||
  !supports["facingMode"]
) {
  // We're missing needed properties, so handle that error.
} else {
  const constraints = {
    width: { min: 640, ideal: 1920, max: 1920 },
    height: { min: 400, ideal: 1080 },
    aspectRatio: 1.777777778,
    frameRate: { max: 30 },
    facingMode: { exact: "user" },
  };

  myTrack
    .applyConstraints(constraints)
    .then(() => {
      /* do stuff if constraints applied successfully */
    })
    .catch((reason) => {
      /* failed to apply constraints; reason is why */
    });
}
Here, after ensuring that the constrainable properties for which matches must be found are supported (width, height, frameRate, and facingMode), we set up constraints which request a width no smaller than 640 and no larger than 1920 (but preferably 1920), a height no smaller than 400 (but ideally 1080), an aspect ratio of 16:9 (1.777777778), and a frame rate no greater than 30 frames per second. In addition, the only acceptable input device is a camera facing the user (a "selfie cam"). If the width, height, frameRate, or facingMode constraints can't be met, the promise returned by applyConstraints() will be rejected.

Note: Constraints which are specified using any or all of max, min, or exact are always treated as mandatory. If any constraint which uses one or more of those can't be met when calling applyConstraints(), the promise will be rejected.

Advanced constraints
So-called advanced constraints are created by adding an advanced property to the constraint set; this property's value is an array of additional constraint sets which are considered optional. There are few if any use cases for this feature, and there is some interest in removing it from the specification, so it will not be discussed here. If you wish to learn more, see section 11 of the Media Capture and Streams specification, past example 2.

Checking capabilities
You can call MediaStreamTrack.getCapabilities() to get a list of all of the supported capabilities and the values or ranges of values which each one accepts on the current platform and user agent. This function returns an object which lists each constrainable property supported by the browser and a value or range of values which are supported for each one of those properties.

For example, the following snippet will result in the user being asked for permission to access their local camera and microphone. Once permission is granted, MediaTrackCapabilities objects will be logged to the console that detail the capabilities of each MediaStreamTrack:

js

Copy
navigator.mediaDevices
  .getUserMedia({ video: true, audio: true })
  .then((stream) => {
    const tracks = stream.getTracks();
    tracks.map((t) => console.log(t.getCapabilities()));
  });
An example capabilities object looks like this:

json

Copy
{
  "autoGainControl": [true, false],
  "channelCount": {
    "max": 1,
    "min": 1
  },
  "deviceId": "jjxEMqxIhGdryqbTjDrXPWrkjy55Vte70kWpMe3Lge8=",
  "echoCancellation": [true, false],
  "groupId": "o2tZiEj4MwOdG/LW3HwkjpLm1D8URat4C5kt742xrVQ=",
  "noiseSuppression": [true, false]
}
The exact contents of the object will depend on the browser and media hardware.

Applying constraints
The first and most common way to use constraints is to specify them when you call getUserMedia():

js

Copy
navigator.mediaDevices
  .getUserMedia({
    video: {
      width: { min: 640, ideal: 1920 },
      height: { min: 400, ideal: 1080 },
      aspectRatio: { ideal: 1.7777777778 },
    },
    audio: {
      sampleSize: 16,
      channelCount: 2,
    },
  })
  .then((stream) => {
    videoElement.srcObject = stream;
  })
  .catch(handleError);
In this example, constraints are applied at getUserMedia() time, asking for an ideal set of options with fallbacks for the video.

Note: You can specify one or more media input device IDs to establish restrictions on which input sources are allowed. To collect a list of the available devices, you can call navigator.mediaDevices.enumerateDevices(), then for each device which meets the desired criteria, add its deviceId to the MediaConstraints object that eventually gets passed into getUserMedia().

You can also change the constraints of an existing MediaStreamTrack on the fly, by calling the track's applyConstraints() method, passing into it an object representing the constraints you wish to apply to the track:

js

Copy
videoTrack.applyConstraints({
  width: 1920,
  height: 1080,
});
In this snippet, the video track referenced by videoTrack is updated so that its resolution as closely as possible matches 1920x1080 pixels (1080p high definition).

Retrieving current constraints and settings
It's important to remember the difference between constraints and settings. Constraints are a way to specify what values you need, want, and are willing to accept for the various constrainable properties (as described in the documentation for MediaTrackConstraints), while settings are the actual values of each constrainable property at the current time.

Getting the constraints in effect
If at any time you need to fetch the set of constraints that are currently applied to the media, you can get that information by calling MediaStreamTrack.getConstraints(), as shown in the example below.

js

Copy
function switchCameras(track, camera) {
  const constraints = track.getConstraints();
  constraints.facingMode = camera;
  track.applyConstraints(constraints);
}
This function accepts a MediaStreamTrack and a string indicating the camera facing mode to use, fetches the current constraints, sets the value of the MediaTrackConstraints.facingMode to the specified value, then applies the updated constraint set.

Getting the current settings for a track
Unless you only use exact constraints (which is pretty restrictive, so be sure you mean it!), there's no guarantee exactly what you're going to actually get after the constraints are applied. The values of the constrainable properties as they actually are in the resulting media are referred to as the settings. If you need to know the true format and other properties of the media, you can obtain those settings by calling MediaStreamTrack.getSettings(). This returns an object based on the dictionary MediaTrackSettings. For example:

js

Copy
function whichCamera(track) {
  return track.getSettings().facingMode;
}
This function uses getSettings() to obtain the track's currently in-use values for the constrainable properties and returns the value of facingMode.

Example: Constraint exerciser
In this example, we create an exerciser which lets you experiment with media constraints by editing the source code describing the constraint sets for audio and video tracks. You can then apply those changes and see the result, including both what the stream looks like and what the actual media settings are set to after applying the new constraints.

The HTML and CSS for this example are pretty simple, and aren't shown here. You can look at the complete code by clicking "Play" to view it in the playground.

Defaults and variables
First we have the default constraint sets, as strings. These strings are presented in editable <textarea>s, but this is the initial configuration of the stream.

js

Copy
Play
const videoDefaultConstraintString =
  '{\n  "width": 320,\n  "height": 240,\n  "frameRate": 30\n}';
const audioDefaultConstraintString =
  '{\n  "sampleSize": 16,\n  "channelCount": 2,\n  "echoCancellation": false\n}';
These defaults ask for a pretty common camera configuration, but don't insist on any property being of special importance. The browser should do its best to match these settings but will settle for anything it considers a close match.

Then we initialize the variables which will hold the MediaTrackConstraints objects for the video and audio tracks, as well as the variables which will hold references to the video and audio tracks themselves, to null.

js

Copy
Play
let videoConstraints = null;
let audioConstraints = null;

let audioTrack = null;
let videoTrack = null;
And we get references to all of the elements we'll need to access.

js

Copy
Play
const videoElement = document.getElementById("video");
const logElement = document.getElementById("log");
const supportedConstraintList = document.getElementById("supportedConstraints");
const videoConstraintEditor = document.getElementById("videoConstraintEditor");
const audioConstraintEditor = document.getElementById("audioConstraintEditor");
const videoSettingsText = document.getElementById("videoSettingsText");
const audioSettingsText = document.getElementById("audioSettingsText");
These elements are:

videoElement
The <video> element that will show the stream.

logElement
A <div> into which any error messages or other log-type output will be written.

supportedConstraintList
A <ul> (unordered list) into which we programmatically add the names of each of the constrainable properties supported by the user's browser.

videoConstraintEditor
A <textarea> element that lets the user edit the code for the video track's constraint set.

audioConstraintEditor
A <textarea> element that lets the user edit the code for the audio track's constraint set.

videoSettingsText
A <textarea> (which is always disabled) that displays the current settings for the video track's constrainable properties.

audioSettingsText
A <textarea> (which is always disabled) that displays the current settings for the audio track's constrainable properties.

Finally, we set the current contents of the two constraint set editor elements to the defaults.

js

Copy
Play
videoConstraintEditor.value = videoDefaultConstraintString;
audioConstraintEditor.value = audioDefaultConstraintString;
Updating the settings display
To the right of each of the constraint set editors is a second text box which we use to display the current configuration of the track's configurable properties. This display is updated by the function getCurrentSettings(), which gets the current settings for the audio and video tracks and inserts the corresponding code into the tracks' settings display boxes by setting their value.

js

Copy
Play
function getCurrentSettings() {
  if (videoTrack) {
    videoSettingsText.value = JSON.stringify(videoTrack.getSettings(), null, 2);
  }

  if (audioTrack) {
    audioSettingsText.value = JSON.stringify(audioTrack.getSettings(), null, 2);
  }
}
This gets called after the stream first starts up, as well as any time we've applied updated constraints, as you'll see below.

Building the track constraint set objects
The buildConstraints() function builds the MediaTrackConstraints objects for the audio and video tracks using the code in the two tracks' constraint set edit boxes.

js

Copy
Play
function buildConstraints() {
  try {
    videoConstraints = JSON.parse(videoConstraintEditor.value);
    audioConstraints = JSON.parse(audioConstraintEditor.value);
  } catch (error) {
    handleError(error);
  }
}
This uses JSON.parse() to parse the code in each editor into an object. If either call to JSON.parse() throws an exception, handleError() is called to output the error message to the log.

Configuring and starting the stream
The startVideo() method handles setting up and starting the video stream.

js

Copy
Play
function startVideo() {
  buildConstraints();

  navigator.mediaDevices
    .getUserMedia({
      video: videoConstraints,
      audio: audioConstraints,
    })
    .then((stream) => {
      const audioTracks = stream.getAudioTracks();
      const videoTracks = stream.getVideoTracks();

      videoElement.srcObject = stream;

      if (audioTracks.length > 0) {
        audioTrack = audioTracks[0];
      }

      if (videoTracks.length > 0) {
        videoTrack = videoTracks[0];
      }
    })
    .then(
      () =>
        new Promise((resolve) => {
          videoElement.onloadedmetadata = resolve;
        }),
    )
    .then(() => {
      getCurrentSettings();
    })
    .catch(handleError);
}
There are several steps here:

It calls buildConstraints() to create the MediaTrackConstraints objects for the two tracks from the code in the edit boxes.
It calls navigator.mediaDevices.getUserMedia(), passing in the constraints objects for the video and audio tracks. This returns a MediaStream with the audio and video from a source matching the inputs (typically a webcam, although if you provide the right constraints you can get media from other sources).
When the stream is obtained, it's attached to the <video> element so that it's visible on screen, and we grab the audio track and video track into the variables audioTrack and videoTrack.
Then we set up a promise which resolves when the loadedmetadata event occurs on the video element.
When that happens, we know the video has started playing, so we call our getCurrentSettings() function (described above) to display the actual settings that the browser decided upon after considering our constraints and the capabilities of the hardware.
If an error occurs, we log it using the handleError() method that we'll look at farther down in this article.
We also need to set up an event listener to watch for the "Start Video" button to be clicked:

js

Copy
Play
document.getElementById("startButton").addEventListener("click", () => {
  startVideo();
});
Applying constraint set updates
Next, we set up an event listener for the "Apply Constraints" button. If it's clicked and there's not already media in use, we call startVideo(), and let that function handle starting the stream with the specified settings in place. Otherwise, we follow these steps to apply the updated constraints to the already-active stream:

buildConstraints() is called to construct updated MediaTrackConstraints objects for the audio track (audioConstraints) and the video track (videoConstraints).
MediaStreamTrack.applyConstraints() is called on the video track (if there is one) to apply the new videoConstraints. If this succeeds, the contents of the video track's current settings box are updated based on the result of calling its getSettings() method.
Once that's done, applyConstraints() is called on the audio track (if there is one) to apply the new audio constraints. If this succeeds, the contents of the audio track's current settings box are updated based on the result of calling its getSettings() method.
If an error occurs applying either set of constraints, handleError() is used to output a message into the log.
js

Copy
Play
document.getElementById("applyButton").addEventListener("click", () => {
  if (!videoTrack && !audioTrack) {
    startVideo();
  } else {
    buildConstraints();

    const prettyJson = (obj) => JSON.stringify(obj, null, 2);

    if (videoTrack) {
      videoTrack
        .applyConstraints(videoConstraints)
        .then(() => {
          videoSettingsText.value = prettyJson(videoTrack.getSettings());
        })
        .catch(handleError);
    }

    if (audioTrack) {
      audioTrack
        .applyConstraints(audioConstraints)
        .then(() => {
          audioSettingsText.value = prettyJson(audioTrack.getSettings());
        })
        .catch(handleError);
    }
  }
});
Handling the stop button
Then we set up the handler for the stop button.

js

Copy
Play
document.getElementById("stopButton").addEventListener("click", () => {
  if (videoTrack) {
    videoTrack.stop();
  }

  if (audioTrack) {
    audioTrack.stop();
  }

  videoTrack = audioTrack = null;
  videoElement.srcObject = null;
});
This stops the active tracks, sets the videoTrack and audioTrack variables to null so we know they're gone, and removes the stream from the <video> element by setting HTMLMediaElement.srcObject to null.

Simple tab support in the editor
This code adds simple support for tabs to the <textarea> elements by making the tab key insert two space characters when either constraint edit box is focused.

js

Copy
Play
function keyDownHandler(event) {
  if (event.key === "Tab") {
    const elem = event.target;
    const str = elem.value;

    const position = elem.selectionStart;
    const beforeTab = str.substring(0, position);
    const afterTab = str.substring(position, str.length);
    const newStr = `${beforeTab}  ${afterTab}`;
    elem.value = newStr;
    elem.selectionStart = elem.selectionEnd = position + 2;
    event.preventDefault();
  }
}

videoConstraintEditor.addEventListener("keydown", keyDownHandler);
audioConstraintEditor.addEventListener("keydown", keyDownHandler);
Show constrainable properties the browser supports
The last significant piece of the puzzle: code that displays, for the user's reference, a list of the constrainable properties which their browser supports. Each property is a link to its documentation on MDN for the user's convenience. See the MediaDevices.getSupportedConstraints() examples for details on how this code works.

Note: Of course, there may be non-standard properties in this list, in which case you probably will find that the documentation link doesn't help much.

js

Copy
Play
const supportedConstraints = navigator.mediaDevices.getSupportedConstraints();
for (const constraint in supportedConstraints) {
  if (Object.hasOwn(supportedConstraints, constraint)) {
    const elem = document.createElement("li");

    elem.innerHTML = `<code><a href='https://developer.mozilla.org/docs/Web/API/MediaTrackSupportedConstraints/${constraint}' target='_blank'>${constraint}</a></code>`;
    supportedConstraintList.appendChild(elem);
  }
}
Error handling
We also have some simple error handling code; handleError() is called to handle promises which fail, and the log() function appends the error message to a special logging <div> box under the video.

js

Copy
Play
function log(msg) {
  logElement.innerHTML += `${msg}<br>`;
}

function handleError(reason) {
  log(
    `Error <code>${reason.name}</code> in constraint <code>${reason.constraint}</code>: ${reason.message}`,
  );
}
Result
Here you can see the complete example in action.

Play

Specifications
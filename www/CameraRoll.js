"use strict";
function CameraRoll() {}

CameraRoll.prototype.count = function (includePhotos, includeVideos, successCallback, errorCallback) {
    if (typeof errorCallback != "function") {
        console.log("CameraRoll.count failure: errorCallback parameter must be a function");
        return
    }
    
    if (typeof successCallback != "function") {
        console.log("CameraRoll.count failure: successCallback parameter must be a function");
        return
    }
    cordova.exec(successCallback, errorCallback, "CameraRoll", "count", [includePhotos, includeVideos]);
};

CameraRoll.prototype.find = function (max, includePhotos, includeVideos, successCallback, errorCallback) {
    if (typeof errorCallback != "function") {
        console.log("CameraRoll.find failure: errorCallback parameter must be a function");
        return
    }

    if (typeof successCallback != "function") {
        console.log("CameraRoll.find failure: successCallback parameter must be a function");
        return
    }
    cordova.exec(successCallback, errorCallback, "CameraRoll", "find", [max, includePhotos, includeVideos]);
};

CameraRoll.install = function () {
    if (!window.plugins) {
        window.plugins = {};
    }
    
    window.plugins.cameraRoll = new CameraRoll();
    return window.plugins.cameraRoll;
};

cordova.addConstructor(CameraRoll.install);
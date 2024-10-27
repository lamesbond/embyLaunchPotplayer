// ==UserScript==
// @name         embyLaunchPotplayer
// @name:en      embyLaunchPotplayer
// @name:zh      embyLaunchPotplayer
// @name:zh-CN   embyLaunchPotplayer
// @namespace    http://tampermonkey.net/
// @version      1.1.0
// @description  emby launch extetnal player
// @description:zh-cn emby调用外部播放器
// @description:en  emby to external player
// @license      MIT
// @author       @bpking
// @github       https://github.com/bpking1/embyExternalUrl
// @include      */web/index.html
// @downloadURL https://update.greasyfork.org/scripts/459297/embyLaunchPotplayer.user.js
// @updateURL https://update.greasyfork.org/scripts/459297/embyLaunchPotplayer.meta.js
// ==/UserScript==

(function () {
    'use strict';
    function init() {
        let playBtns = document.getElementById("ExternalPlayersBtns");
        if (playBtns) {
            playBtns.remove();
        }
        let mainDetailButtons = document.querySelector("div[is='emby-scroller']:not(.hide) .mainDetailButtons");
        let buttonhtml = `<div id="ExternalPlayersBtns" class ="detailButtons flex align-items-flex-start flex-wrap-wrap">
            <button id="embyPot" type="button" class="detailButton  emby-button emby-button-backdropfilter raised-backdropfilter detailButton-primary" title="Potplayer"> <div class="detailButton-content"> <i class="md-icon detailButton-icon button-icon button-icon-left icon-PotPlayer">　</i>  <span class="button-text">Pot</span> </div> </button>
            </div>`
        //这里相比原作者改成afterbegin
        mainDetailButtons.insertAdjacentHTML('afterbegin', buttonhtml)
        document.querySelector("div[is='emby-scroller']:not(.hide) #embyPot").onclick = embyPot;

        //add icons
        document.querySelector("div[is='emby-scroller']:not(.hide) .icon-PotPlayer").style.cssText += 'background: url(https://fastly.jsdelivr.net/gh/bpking1/embyExternalUrl@0.0.5/embyWebAddExternalUrl/icons/icon-PotPlayer.webp)no-repeat;background-size: 100% 100%;font-size: 1.4em';
       }

    function showFlag() {
        let mainDetailButtons = document.querySelector("div[is='emby-scroller']:not(.hide) .mainDetailButtons");
        if (!mainDetailButtons) {
            return false;
        }
        let videoElement = document.querySelector("div[is='emby-scroller']:not(.hide) .selectVideoContainer");
        if (videoElement && videoElement.classList.contains("hide")) {
            return false;
        }
        let audioElement = document.querySelector("div[is='emby-scroller']:not(.hide) .selectAudioContainer");
        return !(audioElement && audioElement.classList.contains("hide"));
    }

    async function embyPot() {
        let url = window.location.href;
        let userid = ApiClient._serverInfo.UserId;
        let apikey = ApiClient.accessToken();
        let poturl = "potplayer://" + url + "&userid=" + userid + "&apikey=" + apikey;
        console.log(poturl);
        window.open(poturl, "_self");
    }


    // monitor dom changements
    document.addEventListener("viewbeforeshow", function (e) {
        if (e.detail.contextPath.startsWith("/item?id=") ) {
            const mutation = new MutationObserver(function() {
                if (showFlag()) {
                    init();
                    mutation.disconnect();
                }
            })
            mutation.observe(document.body, {
                childList: true,
                characterData: true,
                subtree: true,
            })
        }
    });

})();

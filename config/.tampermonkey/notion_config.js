// ==UserScript==
// @name         Tyaba-notion-custom-css
// @version      0.1
// @description  NotionにカスタムCSSを適用させるスクリプト
// @author       Tyaba
// @match        https://www.notion.so/*
// @grant        GM_addStyle
// ==/UserScript==

'use strict';
(function () {
    GM_addStyle(`
    .notion-header-block { background-color: rgba(100, 30, 100, 0.5); color: white; padding-left: 15px;}
    .notion-sub_header-block { background-color: rgba(100, 30, 30, 0.5); color: white;  padding-left: 15px;}
    .notion-sub_sub_header-block { background-color: rgba(50, 50, 100, 0.8);  padding-left: 15px;}
    .notion-topbar { height: 55px; background-color: #333333; !important;}
    .notion-sidebar { background-color: #222222;}
    .window-dragarea { height: 10px; width: 100%;}
    `)
})();
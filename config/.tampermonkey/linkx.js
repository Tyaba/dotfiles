// ==UserScript==
// @name         Tyaba-linkx-auto-update
// @version      0.1
// @description  LinkXの口座を一括更新するスクリプト
// @author       Tyaba
// @match        https://linkx.x.moneyforward.com/
// @grant        none
// ==/UserScript==

'use strict';
(function () {
    // ページ読み込み完了後に実行
    window.addEventListener('load', function () {
        // 更新ボタンを全て取得
        const updateButtons = document.querySelectorAll('.ga-refresh-account-button');

        // 各ボタンを順番にクリック
        let index = 0;
        const clickInterval = setInterval(() => {
            if (index >= updateButtons.length) {
                clearInterval(clickInterval);
                return;
            }

            const button = updateButtons[index];
            button.click();
            index++;

            // 次のクリックまで1秒待機
        }, 1000);
    });
})();

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
    // カスタムボタンを作成
    const customButton = document.createElement('button');
    customButton.textContent = 'Tyaba一括更新';
    customButton.style.position = 'fixed';
    customButton.style.top = '10px';
    customButton.style.right = '10px';
    customButton.style.transform = 'none';
    customButton.style.zIndex = '9999';
    customButton.style.padding = '20px 40px';
    customButton.style.backgroundColor = '#800080';
    customButton.style.color = 'white';
    customButton.style.border = 'none';
    customButton.style.borderRadius = '8px';
    customButton.style.cursor = 'pointer';
    customButton.style.fontSize = '18px';

    // ボタンクリック時の処理
    customButton.addEventListener('click', function () {
        const updateButtons = document.querySelectorAll('.ga-refresh-account-button');
        let index = 0;
        const clickInterval = setInterval(() => {
            if (index >= updateButtons.length) {
                clearInterval(clickInterval);
                return;
            }

            const button = updateButtons[index];
            button.click();
            index++;
        }, 1000);
    });

    // ページにボタンを追加
    document.body.appendChild(customButton);
})();

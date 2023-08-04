import $ from 'jquery';
import { Tooltip } from 'bootstrap';

export function makeCopyButton(contentSelector: string, buttonSelector: string) {
    let contentEl = document.querySelector<HTMLInputElement>(contentSelector)!;
    var t: NodeJS.Timeout;
    $(`${buttonSelector}`).on("click", function () {
        navigator.clipboard.writeText(contentEl.value).then(() => {
            Tooltip.getInstance(buttonSelector)!.setContent({ '.tooltip-inner': "Copied!" })
            $(`${buttonSelector}.btn-primary`).hide();
            $(`${buttonSelector}.btn-success`).show();

            if (t) {
                clearTimeout(t);
            }

            t = setTimeout(() => {
                $(`${buttonSelector}.btn-primary`).show();
                $(`${buttonSelector}.btn-success`).hide();

                Tooltip.getInstance(buttonSelector)!.setContent({ '.tooltip-inner': "Copy to clipboard" })
            }, 2000);
        }, function (err) {
            console.error('Async: Could not copy text: ', err);
        });
    });
}
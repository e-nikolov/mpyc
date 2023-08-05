import qr from "qrcode";
import * as ui from ".";

export const initQRCodeUI = () => {
    ui.showQRCodeButton.addEventListener('shown.bs.tooltip', () => {
        let qrURL = new URL("./", window.location.href) + "?peer=" + ui.myPeerIDEl.value;
        let displayURL = new URL("./", window.location.href) + "?peer=<br/>" + ui.myPeerIDEl.value;
        qr.toCanvas(document.querySelector<HTMLCanvasElement>('#qr')!, qrURL, { errorCorrectionLevel: "H" })
            .then(_ => {
                document.querySelector('#qrURL')!.innerHTML = ui.safe(displayURL);
            })
            .catch(err => {
                console.error(err)
            })
    });
    ui.showQRCodeButton.addEventListener("click", () => {
        document.querySelector<HTMLCanvasElement>('#qr')!.toBlob((blob) => {
            navigator.clipboard.write([new ClipboardItem({ [blob!.type]: blob! })]);
        });
    });
}
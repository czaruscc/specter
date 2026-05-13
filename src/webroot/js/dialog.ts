import { escapeHtml } from './utils.js';
import { getTranslation } from './i18n.js';

export function createDialog(headline: string, content: string, actions: string): MdDialog {
  const dialog = document.createElement('md-dialog');
  dialog.innerHTML = `
    <div slot="headline">${headline}</div>
    <div slot="content">${content}</div>
    <div slot="actions">${actions}</div>
  `;
  document.body.appendChild(dialog);
  dialog.addEventListener('close', () => document.body.removeChild(dialog));
  return dialog;
}

export function showDialog(headline: string, content: string, actions: string): MdDialog {
  const dialog = createDialog(headline, content, actions);
  dialog.show();
  return dialog;
}

export function showConfirm(title: string, message: string): Promise<boolean> {
  return new Promise(resolve => {
    const dialog = showDialog(
      escapeHtml(title),
      `<p class="danger-dialog-msg">${message}</p>`,
      `<md-text-button id="dialog-cancel">${getTranslation('dialog_cancel') || 'Cancel'}</md-text-button>
       <md-filled-button id="dialog-confirm" class="danger-dialog-confirm">${getTranslation('dialog_confirm') || 'OK'}</md-filled-button>`
    );
    dialog.querySelector('#dialog-cancel')!.addEventListener('click', () => { dialog.close(); resolve(false); });
    dialog.querySelector('#dialog-confirm')!.addEventListener('click', () => { dialog.close(); resolve(true); });
  });
}

export function showErrorDialog(title: string, content: string) {
  const dialog = showDialog(
    escapeHtml(title),
    `<div class="error-dialog-content"><div class="terminal"><pre>${escapeHtml(content)}</pre></div></div>`,
    `<md-text-button class="dialog-action-close">${getTranslation('dialog_close') || 'Close'}</md-text-button>`
  );
  dialog.querySelector('.dialog-action-close')!.addEventListener('click', () => dialog.close());
}

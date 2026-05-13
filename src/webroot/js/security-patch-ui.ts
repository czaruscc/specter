import { exec } from './bridge.js';
import { getTranslation } from './i18n.js';
import { showToast } from './toast.js';
import { defaultSecurityPatch } from './constants.js';

const t = (key: string, fallback: string): string => getTranslation(key) || fallback;

export function wireSecurityPatch() {
  const btn = document.getElementById('security-patch-btn');
  if (!btn) return;
  btn.addEventListener('click', () => {
    const defaultDate = defaultSecurityPatch();

    const dialog = document.createElement('md-dialog');
    dialog.innerHTML = `
      <div slot="headline">${t('sp_dialog_title', 'Set Security Patch')}</div>
      <div slot="content" style="min-height:0">
        <md-outlined-text-field id="sp-input" type="text" label="${t('sp_dialog_label', 'Security Patch Date')}" placeholder="YYYY-MM-DD" data-i18n-placeholder="sp_placeholder" maxlength="10" autocapitalize="none" style="width:100%;--md-outlined-text-field-container-shape:14px">
          <md-icon-button slot="trailing-icon" id="sp-generate" aria-label="${t('sp_generate', 'Generate')}">
            <md-icon>autorenew</md-icon>
          </md-icon-button>
        </md-outlined-text-field>
      </div>
      <div slot="actions">
        <md-text-button id="sp-cancel">${t('dialog_cancel', 'Cancel')}</md-text-button>
        <md-filled-tonal-button id="sp-save">${t('dialog_save', 'Save')}</md-filled-tonal-button>
      </div>
    `;
    document.body.appendChild(dialog);

    const input = dialog.querySelector('#sp-input') as MdOutlinedTextField | null;
    if (input) input.value = defaultDate;

    dialog.querySelector('#sp-generate')!.addEventListener('click', () => {
      input!.value = defaultSecurityPatch();
    });

    dialog.querySelector('#sp-cancel')!.addEventListener('click', () => dialog.close());
    dialog.querySelector('#sp-save')!.addEventListener('click', async () => {
      const val = input!.value.trim();
      if (!val || !/^\d{4}-\d{2}-\d{2}$/.test(val)) {
        showToast(t('sp_invalid_date', 'Invalid date format (use YYYY-MM-DD)'), { icon: 'error', type: 'error' as any, autoCloseDelay: 3000 });
        return;
      }
      const content = `system=prop\nboot=${val}\nvendor=${val}`;
      try {
        await exec(`cat > /data/adb/tricky_store/security_patch.txt << 'SEOF'\n${content}\nSEOF`);
        showToast(t('sp_saved', 'Security patch date saved'), { icon: 'check_circle', type: 'success' as any, autoCloseDelay: 2500 });
        dialog.close();
      } catch {
        showToast(t('sp_save_error', 'Failed to save'), { icon: 'error', type: 'error' as any, autoCloseDelay: 4000 });
      }
    });

    dialog.addEventListener('close', () => document.body.removeChild(dialog));
    dialog.show();
  });
}

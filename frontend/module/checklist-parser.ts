// TypeScript mirror of OpenProject::SmartChecklist::Parser.
// The rules must stay identical to lib/open_project/smart_checklist/parser.rb.

export type ChecklistStatus = 'todo' | 'done' | 'in_progress' | 'skipped';

export interface ChecklistEntry {
  type:'header' | 'item';
  text:string;
  status?:ChecklistStatus;
  notes:string[];
}

export interface ChecklistProgress {
  total:number;
  done:number;
  inProgress:number;
  skipped:number;
  todo:number;
  percent:number;
}

const HEADER = /^\s*#{1,3}\s+(.+)$/;
const CHECKBOX = /^\s*-\s*\[( |x|X|~|-)\]\s*(.*)$/;
const NOTE = /^\s*>\s*(.*)$/;
const SHORTHAND = /^\s*([-+~x])\s+(.+)$/;

const SHORTHAND_STATUSES:Record<string, ChecklistStatus> = {
  '-': 'todo',
  '+': 'done',
  '~': 'in_progress',
  x: 'skipped',
};

const CHECKBOX_STATUSES:Record<string, ChecklistStatus> = {
  ' ': 'todo',
  x: 'done',
  X: 'done',
  '~': 'in_progress',
  '-': 'skipped',
};

const STATUS_MARKS:Record<ChecklistStatus, string> = {
  todo: ' ',
  done: 'x',
  in_progress: '~',
  skipped: '-',
};

function appendItem(items:ChecklistEntry[], text:string, status:ChecklistStatus):ChecklistEntry {
  const item:ChecklistEntry = { type: 'item', text: text.trim(), status, notes: [] };
  items.push(item);
  return item;
}

export function parseChecklist(text:string | null | undefined):ChecklistEntry[] {
  const items:ChecklistEntry[] = [];
  let lastItem:ChecklistEntry | null = null;

  for (const raw of (text ?? '').split('\n')) {
    const line = raw.trim();
    if (!line) {
      continue;
    }

    let match = HEADER.exec(line);
    if (match) {
      items.push({ type: 'header', text: match[1].trim(), notes: [] });
      lastItem = null;
      continue;
    }

    match = CHECKBOX.exec(line);
    if (match) {
      lastItem = appendItem(items, match[2], CHECKBOX_STATUSES[match[1]]);
      continue;
    }

    match = NOTE.exec(line);
    if (match) {
      lastItem?.notes.push(match[1]);
      continue;
    }

    match = SHORTHAND.exec(line);
    if (match) {
      lastItem = appendItem(items, match[2], SHORTHAND_STATUSES[match[1]]);
      continue;
    }

    lastItem = appendItem(items, line, 'todo');
  }

  return items;
}

export function serializeChecklist(entries:ChecklistEntry[]):string {
  return entries
    .map((entry) => {
      if (entry.type === 'header') {
        return `# ${entry.text}`;
      }
      const lines = [`- [${STATUS_MARKS[entry.status ?? 'todo']}] ${entry.text}`];
      for (const note of entry.notes) {
        lines.push(`> ${note}`);
      }
      return lines.join('\n');
    })
    .join('\n');
}

export function checklistProgress(text:string | null | undefined):ChecklistProgress {
  const result:ChecklistProgress = { total: 0, done: 0, inProgress: 0, skipped: 0, todo: 0, percent: 0 };

  for (const entry of parseChecklist(text)) {
    if (entry.type !== 'item') {
      continue;
    }
    result.total += 1;
    result[entry.status === 'in_progress' ? 'inProgress' : entry.status!] += 1;
  }

  const countable = result.total - result.skipped;
  result.percent = countable === 0 ? 0 : Math.round((100 * result.done) / countable);
  return result;
}

/** Number of open items (not done, not skipped) — used for the tab badge. */
export function checklistOpenCount(text:string | null | undefined):number {
  return parseChecklist(text)
    .filter((entry) => entry.type === 'item' && entry.status !== 'done' && entry.status !== 'skipped')
    .length;
}

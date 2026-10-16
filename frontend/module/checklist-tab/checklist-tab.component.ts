import { ChangeDetectionStrategy, Component, Injector, Input, inject } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TabComponent } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import {
  ChecklistEntry,
  ChecklistStatus,
  checklistProgress,
  parseChecklist,
  serializeChecklist,
} from '../checklist-parser';

interface ChecklistItemView {
  entry:ChecklistEntry;
  index:number;
}

interface ChecklistSection {
  header:string | null;
  items:ChecklistItemView[];
}

@Component({
  selector: 'opce-smart-checklist-tab',
  templateUrl: './checklist-tab.template.html',
  styleUrls: ['./checklist-tab.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class SmartChecklistTabComponent implements TabComponent {
  @Input() public workPackage:WorkPackageResource;

  @InjectField() halEditing:HalResourceEditingService;

  @InjectField() halEvents:HalEventsService;

  @InjectField() halNotification:HalResourceNotificationService;

  @InjectField() schemaCache:SchemaCacheService;

  readonly I18n = inject(I18nService);

  readonly injector = inject(Injector);

  public rawMode = false;

  public rawText = '';

  public newItemText = '';

  public editingIndex:number | null = null;

  public editingText = '';

  public get entries():ChecklistEntry[] {
    return parseChecklist(this.workPackage.smartChecklist as string);
  }

  public get sections():ChecklistSection[] {
    const sections:ChecklistSection[] = [{ header: null, items: [] }];
    this.entries.forEach((entry, index) => {
      if (entry.type === 'header') {
        sections.push({ header: entry.text, items: [] });
      } else {
        sections[sections.length - 1].items.push({ entry, index });
      }
    });
    return sections.filter((section) => section.header !== null || section.items.length > 0);
  }

  public get progress() {
    return checklistProgress(this.workPackage.smartChecklist as string);
  }

  public get lastIndex():number {
    return this.entries.length - 1;
  }

  public get editable():boolean {
    return this.schemaCache.of(this.workPackage).isAttributeEditable('smartChecklist');
  }

  public statusOf(entry:ChecklistEntry):ChecklistStatus {
    return entry.status ?? 'todo';
  }

  public toggle(entry:ChecklistEntry, index:number):void {
    this.updateItem(index, {
      status: this.statusOf(entry) === 'done' ? 'todo' : 'done',
    });
  }

  public setStatus(index:number, status:ChecklistStatus):void {
    this.updateItem(index, { status });
  }

  public startEdit(index:number, entry:ChecklistEntry):void {
    this.editingIndex = index;
    this.editingText = entry.text;
  }

  public commitEdit():void {
    if (this.editingIndex !== null && this.editingText.trim()) {
      this.updateItem(this.editingIndex, { text: this.editingText.trim() });
    }
    this.editingIndex = null;
  }

  public cancelEdit():void {
    this.editingIndex = null;
  }

  public addItem():void {
    const text = this.newItemText.trim();
    if (!text) {
      return;
    }
    const entries = this.entries;
    entries.push({ type: 'item', text, status: 'todo', notes: [] });
    this.newItemText = '';
    this.save(entries);
  }

  public removeItem(index:number):void {
    const entries = this.entries;
    entries.splice(index, 1);
    this.save(entries);
  }

  public moveItem(index:number, direction:-1 | 1):void {
    const entries = this.entries;
    const target = index + direction;
    if (target < 0 || target >= entries.length) {
      return;
    }
    [entries[index], entries[target]] = [entries[target], entries[index]];
    this.save(entries);
  }

  public itemIndices():number[] {
    return this.entries
      .map((entry, index) => (entry.type === 'item' ? index : -1))
      .filter((index) => index >= 0);
  }

  public enterRawMode():void {
    this.rawText = serializeChecklist(this.entries);
    this.rawMode = true;
  }

  public cancelRawMode():void {
    this.rawMode = false;
  }

  public saveRaw():void {
    this.saveText(this.rawText);
    this.rawMode = false;
  }

  public itemLabel(status:ChecklistStatus):string {
    return this.I18n.t(`js.smart_checklist.status.${status}`);
  }

  private updateItem(index:number, changes:{ text?:string, status?:ChecklistStatus }):void {
    const entries = this.entries;
    Object.assign(entries[index], changes);
    this.save(entries);
  }

  private save(entries:ChecklistEntry[]):void {
    this.saveText(serializeChecklist(entries));
  }

  private saveText(text:string):void {
    const changeset = this.halEditing.changeFor(this.workPackage);
    changeset.projectedResource.smartChecklist = text;
    this.halEditing
      .save(changeset)
      .then((saved) => this.halEvents.push(saved.resource, { eventType: 'updated' }))
      .catch((e) => this.halNotification.handleRawError(e, this.workPackage));
  }
}

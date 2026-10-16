import { Injector, NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Observable, of } from 'rxjs';
import { SmartChecklistTabComponent } from './checklist-tab/checklist-tab.component';
import { checklistOpenCount } from './checklist-parser';

export function workPackageSmartChecklistCount(
  workPackage:WorkPackageResource,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  injector:Injector,
):Observable<number> {
  return of(checklistOpenCount(workPackage.smartChecklist as string));
}

export function initializeSmartChecklistPlugin(injector:Injector) {
  const wpTabService = injector.get(WorkPackageTabsService);
  wpTabService.registerBefore(
    'watchers',
    {
      component: SmartChecklistTabComponent,
      name: I18n.t('js.smart_checklist.tab_name'),
      id: 'smart-checklist',
      displayable: (workPackage) => workPackage.smartChecklist !== undefined,
      count: workPackageSmartChecklistCount,
    },
  );
}

@NgModule({
  imports: [
    OpSharedModule,
  ],
  declarations: [
    SmartChecklistTabComponent,
  ],
  exports: [
    SmartChecklistTabComponent,
  ],
})
export class PluginModule {
  constructor(injector:Injector) {
    initializeSmartChecklistPlugin(injector);
  }
}

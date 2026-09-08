/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import assert from 'assert';
import { URI } from '../../../../../base/common/uri.js';
import { mock } from '../../../../../base/test/common/mock.js';
import { ensureNoDisposablesAreLeakedInTestSuite } from '../../../../../base/test/common/utils.js';
import { IWorkspaceContextService, toWorkspaceFolder, WorkbenchState } from '../../../../../platform/workspace/common/workspace.js';
import { Workspace } from '../../../../../platform/workspace/test/common/testWorkspace.js';
import { IJSONEditingService } from '../../../configuration/common/jsonEditing.js';
import { IExtensionService } from '../../../extensions/common/extensions.js';
import { NativeWorkspaceEditingService } from '../../electron-browser/workspaceEditingService.js';
import { TestContextService } from '../../../../test/common/workbenchTestServices.js';
import { workbenchInstantiationService } from '../../../../test/electron-browser/workbenchTestServices.js';
import { TestInstantiationService } from '../../../../../platform/instantiation/test/common/instantiationServiceMock.js';

class TestNativeWorkspaceEditingService extends NativeWorkspaceEditingService {
	protected override async doEnterWorkspace(workspaceUri: URI) {
		return { workspace: { id: 'test-workspace', configPath: workspaceUri } };
	}
}

suite('NativeWorkspaceEditingService', () => {

	const disposables = ensureNoDisposablesAreLeakedInTestSuite();

	let instantiationService: TestInstantiationService;
	const workspaceUri = URI.file('/test/Untitled-1.code-workspace');

	setup(() => {
		disposables.add(instantiationService = workbenchInstantiationService(undefined, disposables));
		instantiationService.stub(IJSONEditingService, new class extends mock<IJSONEditingService>() { });
	});

	function createExtensionService(): { stopCalls: number; startCalls: number } {
		const calls = { stopCalls: 0, startCalls: 0 };
		instantiationService.stub(IExtensionService, new class extends mock<IExtensionService>() {
			override stopExtensionHosts() {
				calls.stopCalls++;
				return Promise.resolve(true);
			}
			override startExtensionHosts() {
				calls.startCalls++;
				return Promise.resolve();
			}
		});
		return calls;
	}

	test('enterWorkspace from empty window does not restart extension host', async () => {
		const contextService = new TestContextService(new Workspace('empty-workspace'));
		assert.strictEqual(contextService.getWorkbenchState(), WorkbenchState.EMPTY);
		instantiationService.stub(IWorkspaceContextService, contextService);

		const extensionService = createExtensionService();
		const service = disposables.add(instantiationService.createInstance(TestNativeWorkspaceEditingService));
		await service.enterWorkspace(workspaceUri);

		assert.strictEqual(extensionService.stopCalls, 0);
		assert.strictEqual(extensionService.startCalls, 0);
	});

	test('enterWorkspace from folder window restarts extension host', async () => {
		const contextService = new TestContextService(new Workspace('folder-workspace', [toWorkspaceFolder(URI.file('/test/folder'))]));
		assert.strictEqual(contextService.getWorkbenchState(), WorkbenchState.FOLDER);
		instantiationService.stub(IWorkspaceContextService, contextService);

		const extensionService = createExtensionService();
		const service = disposables.add(instantiationService.createInstance(TestNativeWorkspaceEditingService));
		await service.enterWorkspace(workspaceUri);

		assert.strictEqual(extensionService.stopCalls, 1);
		assert.strictEqual(extensionService.startCalls, 1);
	});
});

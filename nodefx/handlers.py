import bpy
import nodefx.nodefx
from time import sleep

test = 0
class NfxModalSimulate(bpy.types.Operator):
    """Operator which runs its self from a timer"""
    bl_idname = "wm.nfx_modal_simulate"
    bl_label = "Nfx Modal Simulate"
    _timer = None
    def modal(self, context, event):
        cframe = bpy.context.scene.frame_current
        tree = bpy.data.node_groups[bpy.context.scene.nfxProcessList[self.iprocess].nfxCurrentTree]
        outNode = tree.nodes[bpy.context.scene.nfxProcessList[self.iprocess].nfxCurrentOut]
        simEndFrame = bpy.context.scene.nfxProcessList[self.iprocess].nfxSimEndFrame
        
        if event.type == 'TIMER':
            sleep(0.1)
            print(str(self.iprocess)+":    "+outNode.name+" process frame:",bpy.context.scene.frame_current)
            outNode.Nfx_updatedFrame = bpy.context.scene.frame_current
            
            if outNode.Nfx_updatedFrame >= simEndFrame:
                self.cancel(context)
                bpy.context.scene.nfxSimulating = False
                outNode.Nfx_updatedFrame = cframe
                return {'FINISHED'}
            else:
                bpy.context.scene.nfxSimulating = True
                bpy.context.scene.frame_current += 1
            


        return {'RUNNING_MODAL'}

    def execute(self, context):
        wm = context.window_manager
        self._timer = wm.event_timer_add(0.01, context.window)
        wm.modal_handler_add(self)
        self.iprocess = bpy.context.scene.nfxProcessIndex
        print('iprocess:',self.iprocess)
        return {'RUNNING_MODAL'}

    def cancel(self, context):
        wm = context.window_manager
        wm.event_timer_remove(self._timer)

#bpy.ops.wm.nfx_modal_simulate()


def nfx_process(tree,outNode):
    process = bpy.context.scene.nfxProcessList.add()
    bpy.context.scene.nfxSimulating = True
    process.nfxCurrentOut = outNode.name
    process.nfxCurrentTree = tree.name
    process.nfxSimEndFrame = bpy.context.scene.frame_current
    bpy.context.scene.frame_current = outNode.Nfx_updatedFrame + 1
    print('nfx_process  cframe:',bpy.context.scene.frame_current,'updatedFrame',outNode.Nfx_updatedFrame,'EndFrame:',process.nfxSimEndFrame)
    bpy.ops.wm.nfx_modal_simulate()
    bpy.context.scene.nfxProcessIndex += 1
    
def nfx_free(tree,outNode):
    outNode.Nfx_updatedFrame = outNode.Nfx_resetFrame
    print('  '+outNode.name+' Data freed')
    
def nfx_frame(context):
    if bpy.context.scene.nfxSimulating == False:
        cframe = bpy.context.scene.frame_current
        bpy.context.scene.nfxProcessIndex = 0
        bpy.context.scene.nfxProcessList.clear()
        print('CURRENTFRAME =',cframe)
        for tree in bpy.data.node_groups:
            if tree.bl_idname == "NfxNodeTree":
                for branchName in tree['Nfx_outNodes']:
                    outNode = tree.nodes[branchName]
                    if cframe > outNode.Nfx_updatedFrame:
                        nfx_process(tree,outNode)
                    elif cframe <= outNode.Nfx_resetFrame:
                        nfx_free(tree,outNode)
                    #print("  ",tree.name,outNode.name)

def register():
    print('NFX handlers loaded')
    bpy.utils.register_class(NfxModalSimulate)
    bpy.app.handlers.persistent(nfx_frame)
    bpy.app.handlers.frame_change_post.append(nfx_frame)
    
def unregister():
    print('NFX handlers unloaded')
    bpy.utils.unregister_class(NfxModalSimulate)

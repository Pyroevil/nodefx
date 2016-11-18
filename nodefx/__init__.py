#====================== BEGIN GPL LICENSE BLOCK ======================
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
#======================= END GPL LICENSE BLOCK ========================

bl_info = {
    "name": "NodeFx addon",
    "author": "Jean-Francois Gallant(PyroEvil)",
    "version": (0, 0, 1),
    "blender": (2, 7, 5),
    "location": "Properties > Object Tab",
    "description": ("Nodefx addon"),
    "warning": "",  # used for warning icon and text in addons panel
    "wiki_url": "http://pyroevil.com/",
    "tracker_url": "http://pyroevil.com/" ,
    "category": "Object"}
import bpy
from bpy.props import FloatVectorProperty,IntProperty,StringProperty,FloatProperty,BoolProperty, CollectionProperty
import importlib
import os
import nodefx.nfxtree
import nodefx.handlers



class nfxProcessList(bpy.types.PropertyGroup):
    nfxCurrentOut = StringProperty()
    nfxCurrentTree = StringProperty()
    nfxSimEndFrame = FloatProperty()


def loadmodules():
    global modules
    node_list = []
    for root,folders,files in os.walk(os.path.dirname(__file__)+"/nodes"):
        for file in files:
            if file[-3:] == ".py":
                node_list.append("nodefx.nodes." + file[:-3])
                modules = []
                for module in node_list:
                    modules.append(importlib.import_module(module))

    
def register():
    nfxtree.register()
    handlers.register()
    loadmodules()
    for module in modules:
        module.register()
    print(__name__)
    bpy.utils.register_module(__name__)
    bpy.types.Scene.nfxProcessList = CollectionProperty(type=nfxProcessList)
    bpy.types.Scene.nfxSimulating = BoolProperty()
    bpy.types.Scene.nfxProcessIndex = IntProperty(default=0)
    

def unregister():
    nfxtree.unregister()
    handlers.unregister()
    for module in modules:
        module.unregister()

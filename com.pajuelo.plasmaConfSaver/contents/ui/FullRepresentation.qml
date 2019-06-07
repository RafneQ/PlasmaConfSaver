/*
 * Copyright 2019 Alberto Pajuelo (paju1986@gmail.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.5
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import Qt.labs.platform 1.0

Item {
    id: "parentItem"
    property real mediumSpacing: 1.5*units.smallSpacing
    property real textHeight: theme.defaultFont.pixelSize + theme.smallestFont.pixelSize + units.smallSpacing
    property real itemHeight: Math.max(units.iconSizes.large, textHeight)
    
    property string loadPath: null
    property string exportPath: null
    property string importPath: null
    property string configPath : StandardPaths.standardLocations(StandardPaths.GenericConfigLocation)[0].split("//")[1] 
    property string dataPath : StandardPaths.standardLocations(StandardPaths.GenericDataLocation)[0].split("//")[1] 
    property string savePath: configPath + "/plasmaConfSaver"
    

    Layout.minimumWidth: widgetWidth + 100
    Layout.minimumHeight: (itemHeight + 2*mediumSpacing) * 10//listView.count

    Layout.maximumWidth: Layout.minimumWidth
    Layout.maximumHeight: Layout.minimumHeight

    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

  
    
    PlasmaCore.DataSource {
		id: executeSource
		engine: "executable"
		connectedSources: []
		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited(sourceName, exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName) // cmd finished
		}
		function exec(cmd) {
			if (cmd) {
				connectSource(cmd)
			}
		}
		signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
	}
	

    

    
    PlasmaCore.DataSource {
        id: placesSource
        engine: 'filebrowser'
        interval: 500
        connectedSources: savePath
    }
    

 
    Column {
        id: col1
         anchors.fill: parent
         Row {
             id: row1
             height:text1.height
             anchors.right: col1.right
             anchors.left: col1.left
           PlasmaComponents.TextField {
             id: text1
             placeholderText: i18n("Enter customization title")
             text: ""
             width: parent.width * 0.8
             
                               
           }
           PlasmaComponents.Button {
             id: button1
             text: ""
             PlasmaCore.IconItem {
                                    anchors.fill: parent
                                    source: "document-save"
                                    active: isHovered
                                    PlasmaCore.ToolTipArea {
                                        anchors.fill: parent
                                        id: tooltip
                                        mainText: i18n("Save")
                                        subText: i18n("Save your current customization")
                                        icon: "document-save"
                                        active: true
                                    }
                                      
                            }
             width: parent.width * 0.1
            
            
            
             
             onClicked: {

                 
                      
                        
                        if(text1.text == "" || text1.text == null || text1.text == undefined) {
                            text1.text = "default"
                        }
                        var configFolder = configPath + "/plasmaConfSaver/" + text1.text
                        
                        
                        
                        executeSource.connectSource("mkdir "+configPath+"/plasmaConfSaver/")
                        executeSource.connectSource("mkdir " + configFolder);
                        
                       // screenshot
                        executeSource.connectSource("scrot " + configFolder + "/screenshot.png")
                        
                       // plasma config files
                        executeSource.connectSource("cp "+configPath+"/plasma-org.kde.plasma.desktop-appletsrc " + configFolder + "/plasma-org.kde.plasma.desktop-appletsrc") 
                        executeSource.connectSource("cp "+configPath+"/plasmarc " + configFolder + "/plasmarc")
                        executeSource.connectSource("cp "+configPath+"/plasmashellrc " + configFolder + "/plasmashellrc")
                        executeSource.connectSource("cp "+configPath+"/kdeglobals " + configFolder + "/kdeglobals")
                        
                        //kwin
                        executeSource.connectSource("cp "+configPath+"/kwinrc " + configFolder + "/kwinrc")
                        executeSource.connectSource("cp "+configPath+"/kwinrulesrc " + configFolder + "/kwinrulesrc")
                        
                        //latte-dock config files
                        executeSource.connectSource("cp "+configPath+"/lattedockrc " + configFolder + "/lattedockrc")
                        executeSource.connectSource("cp -r "+configPath+"/latte " + configFolder + "/latte")
                        
                        //plasma themes and widgets
                        executeSource.connectSource("cp -r "+dataPath+"/plasma " + configFolder + "/plasma")
                        
                        //wallpapers
                        executeSource.connectSource("cp -r "+dataPath+"/wallpapers " + configFolder + "/wallpapers")
                       
                        executeSource.connectSource("pidof latte-dock")

                        
                        
                        
                        
                      listView.forceLayout()
                      
                        
                    }
                    Connections {
                        target: executeSource
                        onExited : {
                            
                    
                        var configFolder = configPath + "/plasmaConfSaver/" + text1.text
                   
                            if(cmd == "pidof latte-dock") {
                                
                                    var latteDockRunning = stdout
                                    
                                    
                                            
                                //if latte-dock was running when we saved then create a flag file for running it on restore            
                                if(latteDockRunning != "") {
                                    executeSource.connectSource("touch " + configFolder + "/latterun")
                                
                                }
                                text1.text = ""
                                
                            }
                            
                            
                            
                            
                            if(cmd.indexOf("kdialog --getsavefilename") != -1) {
                                exportPath = stdout.replace("\n","")
                                executeSource.connectSource("cp " + savePath + "/tmpExport.tar.gz " + exportPath)
                                executeSource.connectSource("rm " + savePath + "/tmpExport.tar.gz")
                            }
                            if(cmd.indexOf("kdialog --getopenfilename") != -1) {
                                importPath = stdout.replace("\n","")
                                var pathArray = importPath.split("/")
                                
                                console.log(pathArray)
                                
                                var fileName = pathArray[pathArray.length - 1]
                                
                                var nameFolder = fileName.split(".")
                                
                                executeSource.connectSource("mkdir " + savePath + "/" + nameFolder[0])
                                
                                executeSource.connectSource("tar xzvf " + importPath + " -C " + savePath + "/" + nameFolder[0])
                                
                                console.log("tar xzvf " + importPath + " -C " + savePath + "/" + nameFolder[0])
                                
                               
                            }
                            
                            
                           
                            
                
                            
                
                
                
                        }
                    }
                               
                }
                PlasmaComponents.Button {
                                 width: 40
                                id: btnImport
                                text: ""
                                PlasmaCore.IconItem {
                                    anchors.fill: parent
                                    source: "document-import"
                                    active: isHovered
                                    PlasmaCore.ToolTipArea {
                                        anchors.fill: parent
                                        mainText: i18n("Import")
                                        subText: i18n("Import a customization")
                                        icon: "document-import"
                                        active: true
                                    }
                                }
                                onClicked:{
                                    executeSource.connectSource("kdialog --getopenfilename $(pwd)")
                                    listView.forceLayout()
                                }
                            }
        }
         
         
         PlasmaExtras.ScrollArea {
       anchors.bottom: col1.bottom
       anchors.top: row1.bottom
       width: widgetWidth + 100
        
        ListView {
            id: listView
            anchors.fill: parent
            model: 
                if(placesSource.data[savePath] != undefined) {
                    return placesSource.data[savePath]["directories.all"]
                } else {
                    return ""
                }
            
            
            highlight: PlasmaComponents.Highlight {}
            highlightMoveDuration: 0
            highlightResizeDuration: 0

            delegate: Item {
                width: parent.width
                height: (mediumSpacing + btnLoad.height + mediumSpacing  + btnDelete.height + mediumSpacing  + btnExport.height +  mediumSpacing)

                property bool isHovered: false
                property bool isEjectHovered: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        listView.currentIndex = index
                        isHovered = true
                    }
                    onExited: {
                        isHovered = false
                    }
                    onClicked: {
                        //expanded = false
                        text1.text = listView.currentIndex.text
                        
                    }

                    Row {
                        x: mediumSpacing
                        y: mediumSpacing
                        width: parent.width - mediumSpacing
                        height: iitemHeight + 11*mediumSpacing
                        spacing: mediumSpacing
                        
//                         Item { // Hack - since setting the dimensions of PlasmaCore.IconItem won't work
//                             height: units.iconSizes.medium
//                             width: height
//                             anchors.verticalCenter: parent.verticalCenter
// 
//                             PlasmaCore.IconItem {
//                                 anchors.fill: parent
//                                 source: jsGetIcon(model.modelData)
//                                 active: isHovered
//                             }
//                         }
                            

                       Column {
                           id: columImage
                            spacing: mediumSpacing
                           width: parent.width - (btnLoad.width + mediumSpacing * 2 )
                           PlasmaComponents.Label {
                               id: title
                                text: model.modelData
                                
                                height: theme.defaultFont.pixelSize
                                elide: Text.ElideRight
                            }
                         
                            Image {
                              id: screenshot
                                 width: ((mediumSpacing + btnLoad.height + mediumSpacing  + btnDelete.height + mediumSpacing  + btnExport.height +  mediumSpacing) - textHeight) * 1.77
                                 height:  (mediumSpacing + btnLoad.height + mediumSpacing  + btnDelete.height + mediumSpacing  + btnExport.height +  mediumSpacing) - textHeight
                          //      anchors.fill: parent
                                fillMode: Image.Stretch
                                source: savePath + "/" + model.modelData + "/screenshot.png"
                            }
                    }
                        
                            Column {
                                 spacing: mediumSpacing
                                
                                
                                PlasmaComponents.Button {
                                    
                                width: 40
                                id: btnLoad
                                text: ""
                                 PlasmaCore.IconItem {
                                    anchors.fill: parent
                                    source: "checkmark"
                                    active: isHovered
                                    PlasmaCore.ToolTipArea {
                                        anchors.fill: parent
                                        mainText: i18n("Load")
                                        subText: i18n("Load this customization")
                                        icon: "checkmark"
                                        active: true
                                    }
                                }
                                onClicked: {
                                    
                                    executeSource.connectSource("nohup sh "+dataPath+"/plasma/plasmoids/com.pajuelo.plasmaConfSaver/contents/scripts/load.sh "+ configPath + " " + savePath + " " + dataPath + " " + model.modelData + " &")
                                    
                                    
                                }
                            
                                
                            }
                            
                            PlasmaComponents.Button {
                                 width: 40
                                id: btnExport
                                text: ""
                                 PlasmaCore.IconItem {
                                    anchors.fill: parent
                                    source: "document-export"
                                    active: isHovered
                                    PlasmaCore.ToolTipArea {
                                        anchors.fill: parent
                                        mainText: i18n("Export")
                                        subText: i18n("Export this customization")
                                        icon: "document-export"
                                        active: true
                                    }
                                }
                                onClicked:{
                                    executeSource.connectSource("tar cvzf " + savePath + "/tmpExport.tar.gz " + "-C "+ savePath + "/" + model.modelData + " ." )
                                    executeSource.connectSource("kdialog --getsavefilename $(pwd)/" + model.modelData +  ".tar.gz ")
                                   
                                    listView.forceLayout()
                                }
                            }
                            
                             PlasmaComponents.Button {
                                 width: 40
                                id: btnDelete
                                text: ""
                                PlasmaCore.IconItem {
                                    anchors.fill: parent
                                    source: "albumfolder-user-trash"
                                    active: isHovered
                                    PlasmaCore.ToolTipArea {
                                        anchors.fill: parent
                                        mainText: i18n("Delete")
                                        subText: i18n("Delete this customization")
                                        icon: "albumfolder-user-trash"
                                        active: true
                                    }
                                }
                                onClicked:{
                                    executeSource.connectSource("rm -Rf " + savePath + "/" + model.modelData)
                                    listView.forceLayout()
                                }
                            }
                                
                            }
                           
                        
                    }
                }
            }
        }
    }
    }

   
     

}

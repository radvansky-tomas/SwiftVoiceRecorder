//
//  RecordingsViewController.swift
//  voice-recorder
//
//  Created by Tomas Radvansky on 20/11/2016.
//  Copyright © 2016 Tomas Radvansky. All rights reserved.
//

import Foundation
import UIKit
import Font_Awesome_Swift
import FDWaveformView
import AVFoundation
import MGSwipeTableCell

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,AVAudioPlayerDelegate,MGSwipeTableCellDelegate {
    
    var data:Array<String> = Array<String>()
    var audioPlayer:AVAudioPlayer?
    @IBOutlet weak var recordButton: ALLocalizableButton!
    @IBOutlet weak var mainTableView: UITableView!
    var activeWaveForm:FDWaveformView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let displayLink = CADisplayLink(target: self, selector: #selector(updateMeters))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        self.recordButton.setFAIcon(icon: .FAMicrophone, forState: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadRecordings()
    }
    
    func loadRecordings() {
        if audioPlayer != nil
        {
            if audioPlayer!.isPlaying
            {
                audioPlayer?.stop()
            }
            audioPlayer = nil
        }
        
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do
        {
            let allFiles:[String] = try FileManager.default.contentsOfDirectory(atPath: documents)
            data = allFiles.filter({ (file:String) -> Bool in
                let url:NSURL = NSURL(fileURLWithPath: file)
                if url.pathExtension == "m4a"
                {
                    return true
                }
                return false
            })
        }
        catch
        {
            data = Array<String>()
        }
        self.mainTableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let recordCell:MGSwipeTableCell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! MGSwipeTableCell
        let createdLabel:UILabel = recordCell.viewWithTag(100) as! UILabel
        let durationLabel:UILabel = recordCell.viewWithTag(101) as! UILabel
        let sizeLabel:UILabel = recordCell.viewWithTag(102) as! UILabel
        let waveForm:FDWaveformView = recordCell.viewWithTag(103) as! FDWaveformView
        let playButton:UIButton = recordCell.viewWithTag(104) as! UIButton
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let currentFile:String = documents + "/" + data[indexPath.row]
        
        do
        {
            if let size = try FileManager.default.attributesOfItem(atPath: currentFile)[FileAttributeKey.size]
            {
                sizeLabel.text = ByteCountFormatter.string(fromByteCount: size as! Int64, countStyle: .file)
            }
            else
            {
                sizeLabel.text = "?"
            }
            
            if let created:Date = try FileManager.default.attributesOfItem(atPath: currentFile)[FileAttributeKey.creationDate] as? Date
            {
                createdLabel.text = created.string(dateStyle: .short, timeStyle: .short, in: nil)
            }
            
            waveForm.audioURL = URL(fileURLWithPath: currentFile)
            waveForm.doesAllowScroll = false
            waveForm.doesAllowScrubbing = false
            waveForm.doesAllowStretch = false
            
            let asset = AVURLAsset(url: URL(fileURLWithPath: currentFile), options: nil)
            let audioDuration = asset.duration
            let audioDurationSeconds:Double = Double(CMTimeGetSeconds(audioDuration))
            durationLabel.text = self.stringFromSeconds(intput: audioDurationSeconds)
            //Prepare play button:
            
            if let playerURL:URL = self.audioPlayer?.url
            {
                if playerURL == URL(string: currentFile)!
                {
                    if self.audioPlayer!.isPlaying
                    {
                        playButton.setFAIcon(icon: .FAStopCircle, forState: .normal)
                    }
                    else
                    {
                        playButton.setFAIcon(icon: .FAPlayCircle, forState: .normal)
                    }
                }
                else
                {
                    playButton.setFAIcon(icon: .FAPlayCircle, forState: .normal)
                }
            }
            else
            {
                playButton.setFAIcon(icon: .FAPlayCircle, forState: .normal)
            }
            
            
            playButton.addTarget(forControlEvents: .touchUpInside, withClosure: { (button:UIControl) in
                do
                {
                    if let playerURL:URL = self.audioPlayer?.url
                    {
                        if playerURL == URL(string: currentFile)!
                        {
                            if self.audioPlayer!.isPlaying
                            {
                                self.audioPlayer?.stop()
                                self.audioPlayer?.currentTime = 0
                            }
                            else
                            {
                                self.audioPlayer?.play()
                            }
                        }
                        else
                        {
                            //Stop other playback and start this one
                            self.audioPlayer?.stop()
                            self.audioPlayer = try AVAudioPlayer(contentsOf: URL(string: currentFile)!)
                            self.audioPlayer?.delegate = self
                            self.audioPlayer?.isMeteringEnabled = true
                            self.audioPlayer?.prepareToPlay()
                            self.audioPlayer?.play()
                            self.activeWaveForm = waveForm
                        }
                    }
                    else
                    {
                        self.audioPlayer = try AVAudioPlayer(contentsOf: URL(string: currentFile)!)
                        self.audioPlayer?.delegate = self
                        self.audioPlayer?.isMeteringEnabled = true
                        self.audioPlayer?.prepareToPlay()
                        self.audioPlayer?.play()
                        self.activeWaveForm = waveForm
                    }
                }
                catch let error as NSError
                {
                    print(error)
                }
                self.mainTableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
            })
        }
        catch
        {
            
        }
        let shareBtn = MGSwipeButton(title: "Share", backgroundColor: UIColor.blue)
        shareBtn.buttonWidth = 80.0
        shareBtn.callback = {
            (sender: MGSwipeTableCell!) -> Bool in
           let activity = UIActivityViewController(activityItems: [URL(fileURLWithPath: currentFile)], applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = shareBtn
            activity.popoverPresentationController?.sourceRect = shareBtn.frame
            self.mainTableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
            self.present(activity, animated: true, completion: nil)
            return true
        }
        
        let deleteBtn = MGSwipeButton(title: "Delete", backgroundColor: UIColor.red)
        deleteBtn.buttonWidth = 80.0
        deleteBtn.callback = {
            (sender: MGSwipeTableCell!) -> Bool in
            
            do
            {
                try FileManager.default.removeItem(atPath: currentFile)
            }
            catch let error as NSError
            {
                print(error)
            }
            self.loadRecordings()
            return true
        }
        recordCell.delegate = self
        recordCell.rightButtons = [shareBtn,deleteBtn]
        
        return recordCell
    }
    
    func stringFromSeconds(intput:Double) -> String {
        
        let seconds:Int = Int(intput.truncatingRemainder(dividingBy: 60.0))
        let minutes:Int = Int((intput / 60.0).truncatingRemainder(dividingBy: 60.0))
        let hours:Int = Int((intput / 3600))
        
        return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
    
    func swipeTableCellWillBeginSwiping(_ cell: MGSwipeTableCell) {
        if self.audioPlayer != nil
        {
            if self.audioPlayer!.isPlaying
            {
                self.audioPlayer!.stop()
            }
        }
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, didChange state: MGSwipeState, gestureIsActive: Bool) {
        if state == .none
        {
            
            self.mainTableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
        }
    }
    
    @IBAction func recordButtonClicked(_ sender: Any) {
        if self.audioPlayer != nil
        {
            self.audioPlayer?.stop()
        }
        self.mainTableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
        self.performSegue(withIdentifier: "RecordSegue", sender: self)
    }
    
    func updateMeters() {
        if self.audioPlayer != nil
        {
            if self.audioPlayer!.isPlaying &&  self.activeWaveForm != nil
            {
                self.audioPlayer!.updateMeters()
                let progress = self.audioPlayer!.currentTime / self.audioPlayer!.duration
                activeWaveForm!.progressSamples = Int(Double(activeWaveForm!.totalSamples) * progress)
                return
            }
        }
        
        activeWaveForm?.progressSamples = 0
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.mainTableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
    }
}

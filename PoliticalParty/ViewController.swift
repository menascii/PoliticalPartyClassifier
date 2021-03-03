//
//  ViewController.swift
//  PoliticalParty
//
//  Created by menascii on 3/1/21.
//


import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
        
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    let sentimentClassifier =  try! political_data(configuration: MLModelConfiguration())
    
    let swifter = Swifter(consumerKey: "consumerKey", consumerSecret: "consumerSecret")


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func predictPressed(_ sender: Any) {
        if let searchText = textField.text {
            
            let searchType = searchText[searchText.index(searchText.startIndex, offsetBy: 0)]
            
            if searchType == "@" {
                self.getTimeline(with: searchText)
            }
            else if searchType == "#" {
                self.searchTweet(with: searchText)
            }
            else {
                self.searchTweet(with: searchText)
            }
        }
    }
    
    func getTimeline (with searchText: String) {
        swifter.getTimeline(
            for: UserTag.screenName(searchText),
            tweetMode: .extended,
            success: {
                    (results) in
                var sentimentScore: Int = 0;
                for i in 0..<100 {
                    if let tweet = results[i]["full_text"].string {
                        self.predictPoliticalParty(with: tweet, sentimentScore: &sentimentScore)
                    }
                }
                self.displayPrediction(with: sentimentScore)
                
                if let url = results[0]["user"]["profile_image_url_https"].string {
                guard let imageURL = URL(string: url) else { return }

                        // just not to cause a deadlock in UI!
                    DispatchQueue.global().async {
                        guard let imageData = try? Data(contentsOf: imageURL) else { return }
                        
                        let image = UIImage(data: imageData)
                        DispatchQueue.main.async {
                            self.profileImage.contentMode = .scaleAspectFit
                            self.profileImage.image = image
                            
                        }
                    }
                }
        })
        {
            (error) in
            print("There was an error retrieving tweets,\(error)")
        }
    }
    
    func searchTweet (with searchText: String) {
        swifter.searchTweet(
            using: searchText,
            lang: "en",
            count: 100,
            tweetMode: .extended,
            success: {
                    (results, metadata) in
                var sentimentScore: Int = 0;
                for i in 0..<100 {
                    if let tweet = results[i]["full_text"].string {
                        self.predictPoliticalParty(with: tweet, sentimentScore: &sentimentScore)
                    }
                }
                self.displayPrediction(with: sentimentScore)
        })
        {
            (error) in
            print("There was an error retrieving tweets,\(error)")
        }
    }
    
    func predictPoliticalParty(with tweet: String, sentimentScore: inout Int) {
        let tweetForClassification = political_dataInput(text: tweet)
        do {
            let prediction = try self.sentimentClassifier.prediction(input: tweetForClassification)
            let sentiment = prediction.label

            if sentiment == "Democrat" {
                sentimentScore += 1
            }
            else if sentiment == "Republican" {
                sentimentScore -= 1
            }
        }
        catch {
            print("There was an error making a prediciton.")
        }
    }
    
    func displayPrediction(with sentimentScore: Int) {
        if sentimentScore > 20 {
            self.sentimentLabel.text = "💙💙🐴Democrat🐴💙💙💙"
        }
        else if sentimentScore > 10 {
            self.sentimentLabel.text = "💙🐴Democrat🐴💙"
        }
        else if sentimentScore > 0 {
            self.sentimentLabel.text = "🐴Democrat🐴"
        }
        else if sentimentScore == 0 {
            self.sentimentLabel.text = "Neutral"
        }
        else if sentimentScore < 0 {
            self.sentimentLabel.text = "🐘Republican🐘"
        }
        else if sentimentScore < 10 {
            self.sentimentLabel.text = "❤️🐘Republican🐘❤️"
        }
        else {
            self.sentimentLabel.text = "❤️❤️🐘Republican🐘❤️❤️"
        }
        self.sentimentLabel.adjustsFontSizeToFitWidth = true
        print(sentimentScore)
    }
}




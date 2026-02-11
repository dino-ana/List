//
//  ToDoCell.swift
//  ToDoList
//
//  Created by Diana on 2/11/26.
//

import UIKit

protocol ToDoCellDelegate: AnyObject {
    func checkmarkTapped(sender: ToDoCell)
}

class ToDoCell: UITableViewCell {
    
    @IBOutlet var isCompleteButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tagLabel: UILabel!
    
    weak var delegate: ToDoCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tagLabel.layer.cornerRadius = 8
        tagLabel.layer.masksToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        tagLabel.setContentHuggingPriority(.required, for: .horizontal)
        tagLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func completeButtonTapped(_ sender: UIButton) {
        delegate?.checkmarkTapped(sender: self)
    }
    
}

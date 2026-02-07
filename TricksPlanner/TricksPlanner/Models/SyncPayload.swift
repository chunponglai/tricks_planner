import Foundation

struct SyncPayload: Codable {
    var categories: [String]
    var tricks: [Trick]
    var templates: [TrainingTemplate]
    var challenges: [Challenge]
    var trainingPlans: [DailyTrainingPlan]

    init(categories: [String] = [],
         tricks: [Trick] = [],
         templates: [TrainingTemplate] = [],
         challenges: [Challenge] = [],
         trainingPlans: [DailyTrainingPlan] = []) {
        self.categories = categories
        self.tricks = tricks
        self.templates = templates
        self.challenges = challenges
        self.trainingPlans = trainingPlans
    }
}

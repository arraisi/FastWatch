import Foundation
import HealthKit

class HealthKitManager {
    private let healthStore = HKHealthStore()
    private let fastingType = HKCategoryType(.mindfulSession)

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }

        let typesToShare: Set<HKSampleType> = [fastingType]
        let typesToRead: Set<HKObjectType> = [fastingType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func saveFast(startTime: Date, endTime: Date, completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }

        let sample = HKCategorySample(
            type: fastingType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startTime,
            end: endTime,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "FastWatchSession": true
            ]
        )

        healthStore.save(sample) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func fetchRecentFasts(days: Int = 7, completion: @escaping ([HKCategorySample]) -> Void) {
        guard isAvailable else {
            completion([])
            return
        }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: fastingType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            let categorySamples = (samples as? [HKCategorySample]) ?? []
            DispatchQueue.main.async {
                completion(categorySamples)
            }
        }

        healthStore.execute(query)
    }
}

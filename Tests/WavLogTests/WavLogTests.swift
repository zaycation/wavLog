import Testing
@testable import WavLog

struct ProjectTests {
    @Test func projectStatusDisplayNames() {
        #expect(Project.Status.wip.displayName == "WIP")
        #expect(Project.Status.shared.displayName == "Shared")
        #expect(Project.Status.complete.displayName == "Complete")
    }

    @Test func projectCodingKeys() throws {
        let json = """
        {
            "id": "test-id",
            "owner_id": "owner-id",
            "title": "Test Beat",
            "status": "wip",
            "is_archived": false,
            "created_at": "2026-06-11T00:00:00Z",
            "updated_at": "2026-06-11T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let project = try decoder.decode(Project.self, from: json)

        #expect(project.title == "Test Beat")
        #expect(project.ownerID == "owner-id")
        #expect(project.status == .wip)
        #expect(project.isArchived == false)
    }
}

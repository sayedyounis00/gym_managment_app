import 'package:gym_managment_app/core/widgets/status_chip.dart';
import '../entities/member_summary.dart';
import '../repositories/members_repository.dart';

class GetMembersParams {
  final String? query;
  final MemberStatusType? statusFilter;

  const GetMembersParams({this.query, this.statusFilter});
}

class GetMembers {
  final MembersRepository repository;

  GetMembers(this.repository);

  Stream<List<MemberSummary>> call([GetMembersParams? params]) {
    return repository.watchMembers(
      query: params?.query,
      statusFilter: params?.statusFilter,
    );
  }
}

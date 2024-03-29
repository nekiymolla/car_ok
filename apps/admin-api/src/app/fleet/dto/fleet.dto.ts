import { Authorize, CursorConnection, FilterableField, IDField, OffsetConnection, UnPagedRelation } from "@nestjs-query/query-graphql";
import { ID, ObjectType } from "@nestjs/graphql";
import { Point } from "@ridy/database";
import { FleetTransactionDTO } from "./fleet-transaction.dto";
import { FleetWalletDTO } from "./fleet-wallet.dto";
import { FleetAuthorizer } from "./fleet.authorizer";

@ObjectType('Fleet')
@UnPagedRelation('wallet', () => FleetWalletDTO, { relationName: 'wallet' })
@OffsetConnection('transactions', () => FleetTransactionDTO)
@Authorize(FleetAuthorizer)
export class FleetDTO {
    @IDField(() => ID)
    id!: number;
    @FilterableField()
    name!: string;
    phoneNumber: string;
    mobileNumber: string;
    accountNumber: string;
    commissionSharePercent!: number;
    commissionShareFlat!: number;
    address?: string;
    exclusivityAreas: Point[][];
}
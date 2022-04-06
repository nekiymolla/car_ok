import { FirebaseAuthenticationService } from '@aginix/nestjs-firebase-admin';
import { Args, Int, Mutation, Query, Resolver } from '@nestjs/graphql';
import { JwtService } from '@nestjs/jwt';
import { SharedRiderService } from '@ridy/order/shared-rider.service';
import { LoginDTO } from './dto/login.dto';
import { LoginInput } from './dto/login.input';
import { VersionStatus } from "@ridy/database/enums/version-status.enum";

@Resolver()
export class AuthResolver {
  constructor(
    private firebaseAuth: FirebaseAuthenticationService,
    private riderService: SharedRiderService,
    private jwtService: JwtService
  ) {}

  @Mutation(() => LoginDTO)
  async login(
    @Args('input', { type: () => LoginInput }) input: LoginInput
  ): Promise<LoginDTO> {
    const decodedToken = await this.firebaseAuth.app
      .auth()
      .verifyIdToken(input.firebaseToken);
    const number = (decodedToken.firebase.identities.phone[0] as string).substring(1);
    const user = await this.riderService.findOrCreateUserWithMobileNumber(
      number
    );
    const payload = { id: user.id };
    return {
      jwtToken: this.jwtService.sign(payload),
    };
  }

  @Query(() => VersionStatus)
  async requireUpdate(@Args('versionCode', { type: () => Int}) versionCode: number) {
    if(process.env.MANDATORY_VERSION_CODE != null  && versionCode < parseInt(process.env.MANDATORY_VERSION_CODE)) {
      return VersionStatus.MandatoryUpdate;
    }
    if(process.env.OPTIONAL_VERSION_CODE != null  && versionCode < parseInt(process.env.OPTIONAL_VERSION_CODE)) {
      return VersionStatus.OptionalUpdate;
    }
    return VersionStatus.Latest;
  }
}
